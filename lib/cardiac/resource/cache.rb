require 'forwardable'

module Cardiac
  module ResourceCache
    
    # This extension allows models to opt-in/opt-out of resource caching for
    # the duration of a block, without regard for whether or not the cache has been configured.
    #
    # This has been "borrowed" from ActiveRecord.
    module ClassMethods
      
      # Enable the resource cache within the block if Cardiac is configured.
      # If it's not, it will execute the given block.
      def cache(&block)
        if ::Cardiac::ResourceCache.configured?
          ::Cardiac::ResourceCache.cache(&block)
        else
          yield
        end
      end

      # Disable the resource cache within the block if Active Record is configured.
      # If it's not, it will execute the given block.
      def uncached(&block)
        if ::Cardiac::ResourceCache.configured?
          ::Cardiac::ResourceAdapter.uncached(&block)
        else
          yield
        end
      end
    end
    
    # Simple middleware for Rack, enabling a resource cache for the duration of the block.
    #
    # Most of this has been "borrowed" from ActiveRecord.
    class Middleware
      def initialize(app)
        @app = app
      end
  
      def call(env)
        enabled = ::Cardiac::ResourceCache.resource_cache_enabled?
        ::Cardiac::ResourceCache.enable_resource_cache!
  
        response = @app.call(env)
        response[2] = Rack::BodyProxy.new(response[2]) do
          restore_resource_cache_settings(enabled)
        end
  
        response
      rescue Exception => e
        restore_resource_cache_settings(enabled)
        raise e
      end
  
      private
  
      def restore_resource_cache_settings(enabled)
        ::Cardiac::ResourceCache.clear_resource_cache
        ::Cardiac::ResourceCache.disable_resource_cache! unless enabled
      end
    end
    
    # The actual implementation of the resource cache.
    #
    # Most of this has been "borrowed" from ActiveRecord.
    module SingletonMethods
      
      # Checks if the resource cache is currently enabled and, optionally, if it applies to the given verb.
      def resource_cache_enabled?(verb=nil)
        @resource_cache_enabled && case verb when NilClass, 'GET', 'HEAD' then true end
      end
      
      # Enable the resource cache within the block.
      def cache
        old, @resource_cache_enabled = @resource_cache_enabled, true
        yield
      ensure
        clear_resource_cache
        @resource_cache_enabled = old
      end
      
      def enable_resource_cache!
        @resource_cache_enabled = true
      end
      
      def disable_resource_cache!
        @resource_cache_enabled = false
      end
      
      # Disable the resource cache within the block.
      def uncached
        old, @resource_cache_enabled = @resource_cache_enabled, false
        yield
      ensure
        @resource_cache_enabled = old
      end
      
      def clear_resource_cache
        @resource_cache.clear
      end
      
      # Fetch the resource from the cache, if present.  Otherwise, yield and store
      # that result in the cache.  Either way, a result will be returned.
      def cache_resource url, headers, event=nil
        if @resource_cache[url].key?(headers)
          event[:name] = 'CACHE' if event
          result = @resource_cache[url][headers]
        else
          result = @resource_cache[url][headers] = yield
        end
        
        result.duplicable? ? result.dup : result
      end
      
    protected
  
      def initialize_resource_cache
        @resource_cache         = Hash.new { |h,url| h[url] = {} }
        @resource_cache_enabled = false
      end
    end
    
    # Checks if the resource cache has been initialized.
    def self.configured?
      ! @resource_cache.nil?
    end
    
    # Make this module a resource cache, and initialize it when the library is loaded.
    extend SingletonMethods
    ActiveSupport.on_load(:cardiac) { ResourceCache.send :initialize_resource_cache }
    
    # Make everyone who includes this module delegate to the single resource cache.
    extend Forwardable
    def_instance_delegators '::Cardiac::ResourceCache', *SingletonMethods.public_instance_methods
    
  end
end
require 'forwardable'

module Cardiac
  class ResourceCache
    
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
    
    # This mixin forwards all calls to the ResourceCache.
    module InstanceMethods
      extend Forwardable
      
      def_instance_delegators '::Cardiac::ResourceCache', *::Cardiac::ResourceCache.public_instance_methods(false)
      protected :cache_resource
    end
    
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

      # Disable the resource cache within the block if Cardiac is configured.
      # If it's not, it will execute the given block.
      def uncached(&block)
        if ::Cardiac::ResourceCache.configured?
          ::Cardiac::ResourceCache.uncached(&block)
        else
          yield
        end
      end
    end
    
    # Simple middleware for Rack, enabling a resource cache for the duration of the block.
    #
    # Most of this has been "borrowed" from ActiveRecord.
    class Middleware
      include InstanceMethods
      
      def initialize(app)
        @app = app
      end
  
      def call(env)
        enabled = resource_cache_enabled?
        enable_resource_cache!
  
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
        clear_resource_cache
        disable_resource_cache! unless enabled
      end
    end
    
    def initialize
      @resource_cache         = Hash.new { |h,url| h[url] = {} }
      @resource_cache_enabled = false
    end
    
    # Checks if the resource cache has been initialized.
    def configured?
      ! @resource_cache.nil?
    end
    
    # Until the load hooks run, we do without a resource cache.
    def self.configured?
    end
    
    # When the load hooks run, we allow resource caching to take place.
    ActiveSupport.on_load(:cardiac) do
      ResourceCache.module_eval do
        extend PerThreadRegistry
        class << self
          remove_method :configured?
        end
      end
    end
    
  end
end
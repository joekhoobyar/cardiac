require 'active_attr/railtie'
require 'cardiac/model'
require 'cardiac/log_subscriber'

module Cardiac
  class Railtie < Rails::Railtie

    # Make the console output logging to STDERR (unless AR already did it).
    console do |app|
      unless defined? ::ActiveRecord::Base
        console = ActiveSupport::Logger.new(STDERR)
        Rails.logger.extend ActiveSupport::Logger.broadcast(console)
      end
    end

    # Rails 4.0+
    if config.respond_to? :eager_load_namespaces
      config.eager_load_namespaces << Cardiac << Cardiac::Model
    end

    # Cardiac
    # ---------------------------------------------------------------------------
        
    config.cardiac = ActiveSupport::OrderedOptions.new
    config.cardiac.client_cache = {}
    config.cardiac.verbose = false
      
    config.app_middleware.insert_after "::ActionDispatch::Callbacks",
      "Cardiac::ResourceCache::Middleware"
      
    initializer 'cardiac.log_subscriber' do |app|
      ActiveSupport.on_load(:cardiac) do
        Cardiac::LogSubscriber.verbose = app.config.cardiac.verbose
      end
    end
      
    initializer 'cardiac.build_client_middleware' do |app|
      ActiveSupport.on_load(:cardiac) do
        Cardiac::Client.tap do |client|
          
          # Optionally print out the rack errors after the request
          client.use Cardiac::Client::ErrorLogger if app.config.cardiac.verbose
          
          # Restore any headers set by the remote server's Rack.
          client.use Cardiac::Client::SwitchHeaders, /^X-HideRack-/, 'X-Rack-'
  
          # Rename any headers set by the local client's Rack.
          client.use Cardiac::Client::SwitchHeaders, /^X-Rack-/, 'X-Rack-Client-'
          
          # Unless disabled, configure the client's Rack cache.  
          # NOTE: Certain headers should ALWAYS be ignored by the client.
          if client_cache = app.config.cardiac.client_cache
            client_cache = {} unless Hash===client_cache
            client_cache[:verbose] = false unless client_cache.key? :verbose
            client_cache[:ignore_headers] = Array(client_cache[:ignore_headers]) + ['Set-Cookie','X-Content-Digest']
              
            client.use Rack::Cache, Hash[ client_cache.map{|k,v| ["rack-cache.#{k}", v] } ]
          end
  
          # This is the "meat" of our basic middleware.
          client.use Rack::Head
          client.use Rack::ConditionalGet
          client.use Rack::ETag
  
          # Hide any headers set by the remote server's Rack.
          client.use Cardiac::Client::SwitchHeaders, /^X-Rack-/, 'X-HideRack-'
        
        end
      end
    end
      
    
    # Cardiac::Model
    # ---------------------------------------------------------------------------
      
    config.cardiac_model = ActiveSupport::OrderedOptions.new

    initializer "cardiac_model.logger" do
      ActiveSupport.on_load(:cardiac_model) do
        self.logger ||= ::Rails.logger
      end
    end
    
    # Rails 4.2+, or when the GlobalID gem is explicitly loaded.
    initializer 'cardiac_model.global_id' do
      ActiveSupport.on_load(:cardiac_model) do
        if defined? ::GlobalID
          require 'global_id/identification'
          send :include, ::GlobalID::Identification
        end
      end
    end

    # Make sure that the model layer is already available when running a script.
    runner do
      require 'cardiac/model/base'
    end
  end
end
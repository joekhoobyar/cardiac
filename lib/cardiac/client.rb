require 'rack'
require 'rack/client'
require 'rack/cache'
require 'stringio'

module Cardiac
  
  class Client < Rack::Client::Simple
    
    # :nodoc:
    class ErrorLogger
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        if message = env['rack.errors'].string.presence
          Cardiac::Model::Base.logger.error "cardiac: #{message}"
        end
      end
    end
    
    # :nodoc:
    class SwitchHeaders
      def initialize(app,match,switch)
        @app, @match, @switch = app, match, switch
      end

      def call(env)
        status, headers, body = @app.call(env)
        [status, Hash[ headers.to_a.map{|k,v| [@match===k ? @switch+$' : k, v] }], body]
      end
    end
    
    def build_env(*)
      env = super
    end

    def http_user_agent
      "cardiac #{Cardiac::VERSION} (rack-client #{Rack::Client::VERSION})"
    end

    def self.new
      super Rack::Client::Handler::NetHTTP
    end

    def self.request(*args)
      @instance ||= new
      @instance.request(*args)
    end
    
    def self.build_mock_response body, code, headers={}
      case body
      when Exception
        body = StringIO.new([body.to_s].concat(body.backtrace).join("\n\t"))
      else
        body = StringIO.new(body.to_s)
      end
      headers['Status'] ||= code.to_s
      Rack::Client::Simple::CollapsedResponse.new code, headers, body
    end
  end
end
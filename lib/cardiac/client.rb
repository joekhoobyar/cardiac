require 'rack'
require 'rack/client'
require 'rack/cache'
require 'stringio'

module Cardiac
  
  class Client < Rack::Client::Simple
    
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

    # Restore any headers set by the remote server's Rack.
    use SwitchHeaders, /^X-HideRack-/, 'X-Rack-'

    # Rename any headers set by the local client's Rack.
    use SwitchHeaders, /^X-Rack-/, 'X-Rack-Client-'

    # This is the "meat" of our basic middleware.
    use Rack::Cache,
    'rack-cache.ignore_headers' => ['Set-Cookie','X-Content-Digest']
    use Rack::Head
    use Rack::ConditionalGet
    use Rack::ETag

    # Hide any headers set by the remote server's Rack.
    use SwitchHeaders, /^X-Rack-/, 'X-HideRack-'

    def self.new
      super Rack::Client::Handler::NetHTTP
    end

    def self.request(*args)
      @instance ||= new
      @instance.request(*args)
    end
    
    def self.build_mock_response body, code, headers={}
      Rack::Client::Simple::CollapsedResponse.new code, headers, StringIO.new(body)
    end

    def http_user_agent
      "cardiac #{Cardiac::VERSION} (rack-client #{Rack::Client::VERSION})"
    end
  end
end
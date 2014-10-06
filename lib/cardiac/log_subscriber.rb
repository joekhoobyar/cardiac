module Cardiac
  
  class LogSubscriber < ActiveSupport::LogSubscriber
    class_attribute :verbose
    self.verbose = false
    
    delegate :logger, to: '::Cardiac::Model::Base'

    def initialize
      super
      @odd_or_even = false
    end

    def operation(event)
      return unless logger.debug?

      payload   = event.payload
      name, url, verb, result = *payload.values_at(:name, :url, :verb, :result)
      
      cache_trace = result.headers['X-Rack-Client-Cache'] if result
        
      stats = "#{event.duration.round(1)}ms"
      stats = "CACHED #{stats}" if cache_trace && name!='CACHE' && /fresh/ === cache_trace
      name  = "#{name} #{verb} (#{stats})"
      
      if extra = payload.except(:name, :verb, :url, :result).presence
        extra = extra.map{|key,value|
                   key = key.to_s.underscore.upcase
                   "\n\t +#{key}: #{key=='PAYLOAD' ? value : value.inspect}"
                 }
      end
      
      if verbose && result
        verbosity = Hash===verbose ? verbose : {status: true, cache: true, headers: false, body: false}
        extra ||= []
        extra.unshift "\n\t +BODY: #{body.inspect}" if verbosity[:body]
        extra.unshift "\n\t +HEADERS: #{headers.inspect}" if verbosity[:headers]
        extra.unshift "CACHE: #{cache_trace}" if verbosity[:cache]
        extra.unshift result.status if verbosity[:status]
      end

      if odd?
        name = color(name, CYAN, true)
        url  = color(url, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name}  #{url}#{'  ['+extra.join('; ')+']' if extra}"
    end

    def identity(event)
      return unless logger.debug?

      name = color(event.payload[:name], odd? ? CYAN : MAGENTA, true)
      line = odd? ? color(event.payload[:line], nil, true) : event.payload[:line]

      debug "  #{name}  #{line}"
    end

    def odd?
      @odd_or_even = !@odd_or_even
    end
  end
      
  # Make sure that the log subscriber is listening for events.
  LogSubscriber.attach_to :cardiac
end

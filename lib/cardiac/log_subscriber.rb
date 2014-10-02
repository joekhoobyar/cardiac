module Cardiac
  
  class LogSubscriber < ActiveSupport::LogSubscriber
    
    delegate :logger, to: '::Cardiac::Model::Base'

    def initialize
      super
      @odd_or_even = false
    end

    def operation(event)
      return unless logger.debug?

      payload = event.payload

      name  = "#{payload[:name]} #{payload[:verb]} (#{event.duration.round(1)}ms)"
      url   = payload[:url]

      if extra = payload.except(:name, :verb, :url).presence
        extra = "  " + extra.map{|key,value|
                   key = key.to_s.underscore.upcase
                   "#{key}: #{key=='PAYLOAD' ? value : value.inspect}"
                 }.join(",\n\t +")
      end

      if odd?
        name = color(name, CYAN, true)
        url  = color(url, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name}  #{url}#{extra}"
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

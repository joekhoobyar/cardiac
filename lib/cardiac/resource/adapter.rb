require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/callbacks'
require 'active_support/configurable'
require 'active_support/rescuable'

module Cardiac
  
  # An adapter for performing operations on a resource.
  class ResourceAdapter
    include ::ActiveSupport::Callbacks
    
    define_callbacks :resolve, :prepare, :encode, :execute, :decode
    
    attr_accessor :klass, :resource, :payload, :result
    
    delegate :request_has_body?, :response_has_body?, to: :resource
    delegate :encoder_reflection, :decoder_reflections, to: '@reflection'
    delegate :transmitted?, :aborted?, :completed?, :response, to: :result, allow_nil: true

    # Use instrumentation to perform logging.
    # @see ActiveSupport::Notifications
    delegate :instrumenter, to: '::ActiveSupport::Notifications'
    delegate :logger, to: '::Cardiac::Model::Base'
    
    def initialize(klass,base,payload=nil)
      @klass = klass
      @reflection = base.to_reflection if base.respond_to?(:to_reflection)
      run_callbacks :resolve do
        @resource = base.to_resource if base.respond_to?(:to_resource)
      end
      @reflection ||= @resource.to_reflection if resolved?
    end
    
    def __client_options__
      if resolved?
        @__client_options__ ||= resource.send(:build_client_options)
      end
    end
    
    # Convenience method to return the current HTTP verb
    def http_verb
      if defined? @__client_options__
        @__client_options__[:method].to_s.upcase
      end
    end
    
    # Performs a remote call by performing the remaining phases in the lifecycle of this adapter.
    def call! *arguments, &block
      self.result = nil
      
      resolved? or raise UnresolvableResourceError
      prepared? or prepare! or raise InvalidOperationError
      encode! *arguments
      execute!
    ensure
      decode! if completed?
    end
    
    def resolved?
      resource.present?
    end
    
    def prepared?
      __client_options__.present?
    end
    
  protected
  
    def prepare! verb=nil
      run_callbacks :prepare do
        verb ? resource.http_method(verb) : resource
      end
      __client_options__.symbolize_keys!
      prepared?
    end

    def encode! *arguments
      
      # Allow the payload to be overridden by a single argument.
      if arguments.length == 1
        self.payload = arguments.first
      elsif arguments.length > 1
        raise ArgumentError, "wrong number of arguments (#{arguments.length} for 0..1)"
      end
      
      # Build the remaining portion of the operation using the given payload.
      if request_has_body?
        raise InvalidOperationError, "#{http_verb} requires a payload" if payload.nil?
        run_callbacks :encode do
          self.payload = encoder_reflection.base_reflection.coder.encode(payload)
        end
      elsif payload.present?
        raise InvalidOperationError, "#{http_verb} does not support a payload"
      end
    end
    
    def execute!
      instrumenter.instrument "operation.cardiac", event_attributes do
        run_callbacks :execute do
          handler = __handler__.new(__client_options__, payload, &__client_handler__)
          self.result = handler.transmit!
          completed?
        end
      end
    rescue => e
      message = "#{e.class.name}: #{e.message}: #{resource.to_url}"
      logger.error message if logger
      raise e
    end
    
    def decode! response=self.response
      return unless response_has_body?
      
      unless content_type = response.content_type.presence
        raise ProtocolError, 'missing Content-type in response'
      end
     
      unless decoder = decoder_reflections.find{|dr| dr.base_reflection.matches?(content_type) }
        raise ResourceError, "no decoder for #{content_type.inspect} response"
      end
      
      run_callbacks :decode do
        result.payload = decoder.base_reflection.coder.decode(response.body.to_s)
      end
    end

  private
  
    def model_name
      __klass_get(:model_name).try(:to_s)
    end
    
    def event_attributes
      h = { name: model_name, verb: http_verb, url: resource.to_url, payload: payload }
      ctx = __klass_get :operation_context
      ctx = { context: ctx } unless ctx.present? && Hash===ctx
      h.reverse_merge! ctx if ctx
      h.keep_if{|key,value| key==:verb || key==:url || value.present? }
    end
    
    def __codecs__
      @__codecs__ ||= ::Cardiac::Representation::Codecs
    end
  
    def __handler__
      @__handler__ ||= ::Cardiac::OperationHandler
    end
    
    def __client_handler__
    end
    
    def __klass_get method_name
      @klass.public_send(method_name) if @klass && @klass.respond_to?(method_name, false)
    end
  end

end

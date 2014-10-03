require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/callbacks'
require 'active_support/configurable'
require 'active_support/rescuable'

module Cardiac
  
  # An adapter for performing operations on a resource.
  class ResourceAdapter
    include ::ActiveSupport::Callbacks
    include Representation::LookupMethods
    include ResourceCache::InstanceMethods
    
    define_callbacks :resolve, :prepare, :encode, :execute, :decode
    
    attr_accessor :klass, :resource, :payload, :result
    
    delegate :request_has_body?, :response_has_body?, :request_is_safe?, :request_is_idempotent?, to: :resource
    delegate :encoder_reflection, :decoder_reflections, to: '@reflection'
    delegate :transmitted?, :aborted?, :completed?, :response, to: :result, allow_nil: true

    # Use instrumentation to perform logging.
    # @see ActiveSupport::Notifications
    delegate :instrumenter, to: '::ActiveSupport::Notifications'
    delegate :logger, to: '::Cardiac::Model::Base'
    
    def initialize(klass,base,payload=nil)
      @klass               = klass
      @reflection          = base.to_reflection if base.respond_to? :to_reflection
      resolve! base
    end
    
    def __client_options__
      if resolved?
        @__client_options__ ||= resource.send(:build_client_options).tap do |h|
          h = (h[:headers] ||= {})
            
          # Content-Type
          if content_type = h.delete(:content_type).presence
            content_type = mimes_for(content_type).first
          else
            content_type = encoder_reflection.base_reflection.default_type
          end
          h['content_type'] = content_type.try(:content_type) || 'application/x-www-form-urlencoded'
              
          # Accept
          if accept = h.delete(:accepts).presence and Array===accept
            accept = accept.map{|ext| mimes_for(ext.to_s.strip).first }
          else
            accept = decoder_reflections.map{|dr| dr.base_reflection.default_type }.compact
          end
          h['accept'] = accept.empty? ? '*/*; q=0.5, application/json' : accept.join('; ')
        end
      end
    end
    
    # Convenience method to return the current HTTP verb
    def http_verb
      @http_verb ||= (defined? @__client_options__ and @__client_options__[:method].to_s.upcase)
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
      @__client_options__.present?
    end
    
  protected
  
    def resolve! base
      run_callbacks :resolve do
        @resource = base.to_resource if base.respond_to?(:to_resource)
      end
      @reflection ||= @resource.to_reflection if resolved?
    end
  
    def prepare! verb=nil
      run_callbacks :prepare do
        if verb
          self.resource = resource.http_method(verb)
          @__client_options__ = nil
        end
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
      run_callbacks :execute do
        clear_resource_cache unless request_is_safe?
          
        instrumenter.instrument "operation.cardiac", event=event_attributes do
          if resource_cache_enabled? http_verb
            self.result = cache_request(*__client_options__.slice(:url, :headers)) { transmit! }
          else
            self.result = transmit!
          end
          event[:response_headers] = result.response.headers if result && result.response
        end
            
        completed?
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
  
    def transmit!
      __handler__.new(__client_options__, payload, &__client_handler__).transmit!
    end
   
    def model_name
      __klass_get(:model_name).try(:to_s)
    end
    
    def event_attributes(name=model_name)
      h = { name: name, verb: http_verb, url: resource.to_url, payload: payload }
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

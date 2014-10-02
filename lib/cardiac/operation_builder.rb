module Cardiac
  class OperationBuilder < ResourceBuilder
    attr_writer :klass

  protected
  
    # Checks if the given HTTP method is allowed.
    def http_method_allowed?(verb=@base.method_value)
      @base.allowed_http_methods.include?(verb)
    end

  private
  
    # Overridden to support :call when a verb is implied.
    def respond_to_missing?(name,include_private=false)
      unless name == :call then super else 
        @base.method_value.present? && http_method_allowed?(@base.method_value)
      end
    end
  
    # Overridden to respond to HTTP verbs.
    def check_builder_method?(name)
      super(name) || http_method_allowed?(name)
    end
    
    # Overridden to respond to HTTP verbs.
    def method_missing name, *args, &block
      name = @base.send(:build_method) if name == :call
      if http_method_allowed? name
        call!(name, *args, &block)
      else
        super
      end
    end
    
    # This builder does not actually perform calls, but does record the HTTP verb.
    def call!(name, *args, &block)
      if @base.method_value==name then self else
        build! :http_method, name
      end
    end
    
    # Overridden to assign the :klass.
    def build!(name, *args, &block)
      b = super
      b.klass = @klass
      b
    end
    
    # Overridden to assign the :klass.
    def extend!(*extensions, &extension_block)
      b = super
      b.klass = @klass
      b
    end
  end
  
  class OperationProxy < OperationBuilder
    
  private
    
    # Overridden to actually perform the call and return the payload.
    def call!(name, *args, &block)
      built = super
      resolved = __adapter__.new(@klass, built.to_resource)
      resolved.call!(*args, &block)
      resolved.result.payload
    end
  
    def __adapter__
      @__adapter__ ||= ::Cardiac::ResourceAdapter
    end
    
  end
end
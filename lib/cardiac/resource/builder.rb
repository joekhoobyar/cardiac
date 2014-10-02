module Cardiac
  class ResourceBuilder < Proxy
    
    def initialize base, *extensions, &extension_block
      raise ArgumentError unless Resource === base
      @base, @extensions, @extension_block = base, extensions, extension_block
      @extensions.compact!
    end

    # Returns a copy of our subresource.
    def to_resource
      __subresource__.dup
    end
    
    # Resolves this builder's extension module, and extends the builder with it.
    def __extension_module__
      @__extension_module__ ||= build_extensions_for_module!{|mod| __extend__ mod }
    end
    
    # Resolves this builder's extensions.
    def __extensions__
      @__extensions__ ||= @extensions.dup.tap do |exts|
        exts.unshift @base.__extension_module__ if @base.__extension_module__
        exts.push ::Module.new(&@extension_block) if @extension_block
      end
    end
    
    # Resolves this builder to a subresource.
    def __subresource__
      @__subresource__ ||= Subresource.new(@base.to_resource)
    end
    
    def extending(*extensions,&extension_block)
      extend! extensions, &extension_block
    end
    
  protected
  
    # Includes this builder's extensions into the given module, returning that module.
    # If no module is supplied, then a new module will be built.
    def build_extensions_for_module!(mod=nil,&block)
      if __extensions__.any?
        mod ||= ::Module.new
        mod.send :include, *__extensions__
        block.call mod if block
      end
      mod
    end
    
  private
    
    def method_missing name, *args, &block
      name = name.to_sym
      
      # Always delegate builder methods.
      if check_builder_method? name
        build! name, *args, &block

      # Only delegate extension methods if the extension module has not been built yet.
      # This allows extensions to be removed by preventing method_missing from calling them.
      elsif @__extension_module__.nil? && check_extension_method?(name)
        #__extension_module__.instance_method(name).bind(self).call(*args, &block)
        __public_send__(name, *args, &block) || self
        
      # Otherwise, the method has not been implemented.
      else
        raise ::NotImplementedError, "#{name.inspect} is not implemented for this builder"
      end
    end
    
    # Clones our subresource, calls it with the given args, then returns a new builder for it.
    def build! name, *args, &block
      subr = to_resource
      subr.send name, *args, &block
      __class__.new subr, *(@extensions+[subr.__extension_module__])
    end
  
    # Clones our subresource, extends it with the given extensions, then creates a new builder with an extension block
    def extend! extensions, &extension_block
      subr = to_resource.extending(*extensions)
      subr = DeclarationBuilder.new(subr).extension_exec(&extension_block) if extension_block
      __class__.new subr, *(@extensions+[subr.__extension_module__])
    end
    
    # Checks if this builder can respond to a symbol.
    def respond_to_missing?(name, include_private=false)
      check_builder_method?(name) || check_extension_method?(name)
    end
    
    # Checks if the given builder method is allowed.
    def check_builder_method? name
      name = name.to_sym
      name!=:subresource && name!=:operation && (@base.allowed_builder_methods.include?(name))
    end
    
    # Checks if the given extension method is allowed.
    def check_extension_method? name
      __extension_module__.method_defined? name if __extensions__.any?
    end
    
#    def method_added name, &block
#      @extensions.send :define_method, name, &block
#      remove_method name if method_defined? name
#    end
  end
  
end
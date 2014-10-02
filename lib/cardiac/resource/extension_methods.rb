require 'active_support/core_ext/module/remove_method'

module Cardiac
  
  module ExtensionMethods
    
    # Defines an operation on this resource.    
    def operation(name, implementation)
      self.operations_values << check_operation(name, implementation)
      self
    end
    
    # Defines a subresource on this resource.    
    def subresource(name, implementation, &extension_block)
      self.subresources_values << check_subresource(name, implementation, extension_block)
      self
    end
    
    # Declares an extension module to be included into this resource's extension module.
    def extending(*modules, &extension_block)
      self.extensions_values += check_extensions(modules, extension_block)
      self
    end

    # Lazily builds the extension module, then redefines this method as an attr_reader.
    def __extension_module__
      build_extension_module if extensions_values.any? || operations_values.any? || subresources_values.any?
    ensure
      singleton_class.class_eval "attr_reader :__extension_module__"
    end
    
    # Checks if an extension is defined.
    def __extension_defined__?(name)
      __extension_module__.method_defined? name
    end
    
  protected
  
    def build_extension_module
      @__extension_module__ = apply_extensions_to_module!
    end
    
    def build_operations_for_module mod
      operations_values.inject({}.with_indifferent_access){|h,(k,v)| h[k]=v ; h }.
        each{|name,block| mod.redefine_method(name, &block) }
    end
    
    def build_subresources_for_module mod, subm=Module.new
			[subm, subresources_values.
					inject({}.with_indifferent_access){|h,(k,v,e)| h[k]=[v,e] ; h }.
					each do |name,(block,extension_block)|
						subm.redefine_method(name, &block)
						if extension_block
              stash_object_in_method! subm, :"__#{name}_extensions__", extension_block
						end
					end]
    end
    
    def build_extensions_for_module mod
      extensions_values.each{|ext| mod.send :include, ext }
    end
    
  private
  
    def check_operation name, implementation
      raise ArgumentError unless Proc===implementation
      raise ArgumentError unless String===name || Symbol===name
      name = name.to_sym
      return [name, implementation] unless subresources_values.any?{|v| v.first==name }
      raise ArgumentError, ":#{name} has already been defined as a subresource"
    end
  
    def check_subresource name, implementation, extension_block
      raise ArgumentError unless Proc===implementation
      raise ArgumentError unless String===name || Symbol===name
      raise ArgumentError unless extension_block.nil? || extension_block.arity==0
      name = name.to_sym
      return [name, implementation, extension_block] unless operations_values.any?{|v| v.first==name }
      raise ArgumentError, ":#{name} has already been defined as an operation"
    end
    
    def check_extensions modules, extension_block
      raise ArgumentError unless modules.all?{|mod| Module===mod}
      raise ArgumentError unless extension_block.nil? || extension_block.arity==0
      modules << Module.new(&extension_block) if extension_block
      modules
    end
    
    def apply_extensions_to_module! mod=Module.new
      build_extensions_for_module mod

			subm, subr = build_subresources_for_module mod
			if subm && subr && subr.any?
				mod.send :include, subm
				subr.each do |name,(_,extension_block)|
						mod.module_eval <<-EOVR
	def #{name}(*args)
		super(*args)#{".extending(&__#{name}_extensions__)" if extension_block}
	end
	EOVR
				end
			end

			build_operations_for_module mod
			mod
    end
    
    def stash_object_in_method! mod, name, object
      mod.module_exec object do |_object|
        define_method(name) { object }
      end
    end
  end
  
end

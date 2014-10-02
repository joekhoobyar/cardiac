module Cardiac
  
  # If a subresource has any path or query values, it will treat the base resource's path
  # as being a *directory*.  
  class Subresource < Resource

		begin
			remove_method :subresource, :subresources_values
			private :subresources_values=
		rescue
		end
    
    def initialize(base)
      @_base_resource = base
      super base.base_value
      self.method_value = base.method_value
    end
     
    # Overridden to enforce the appending of subresource paths.
    def base_value
      base_path = @_base_resource.build_path
      base_path+='/' if @path_values.any? && base_path[-1]!='/'
      super.merge URI::Generic.build(path: base_path)
    end
  
    # Lazily builds the parent module, then redefines this method as an attr_reader.
    def __parent_module__
      build_parent_module
    ensure
      singleton_class.class_eval "attr_reader :__parent_module__"
    end
      
  protected
  
    def build_scheme
      @https_value.nil? ? @_base_resource.build_scheme : super
    end
    
    def build_host
      @host_value.nil? ? @_base_resource.build_host : super
    end
    
    def build_port(scheme=nil)
      @port_value.nil? ? @_base_resource.build_port(scheme) : super
    end
    
    def build_query_values
      @_base_resource.build_query_values + @query_values.select(&:present?)
    end
  
    def build_options(base_options=nil)
      super @_base_resource.send(:build_options, base_options||{})
    end
    
    def build_headers(base_headers=nil)
      super @_base_resource.send(:build_headers, base_headers||{})
    end
    
    def build_config(base_config=nil)
      super @_base_resource.send(:build_config, base_config||{})
    end
    
    def build_parent_module
      @__parent_module__ ||= Module.new.tap{|x| @_base_resource.build_extensions_for_module x }
    end
    
    def build_subresources_for_module mod
      raise NotImplementedError
    end

		def build_encoder(*previous)
			result = @_base_resource.send :build_encoder, *previous
			result[0] = encoder_search_value || result[0]
			result
		end
    
  private
  
    # Overridden to omit any subresources.    
    def apply_extensions_to_module! mod=Module.new
      mod.send :include, build_parent_module
      build_extensions_for_module mod
      build_operations_for_module mod
      mod
    end
      
  end
end

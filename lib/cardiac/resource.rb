require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/blank'

module Cardiac
  class Resource
    
    attr_accessor :base_value,
      
      # built by: UriMethods
      :https_value, :user_value, :password_value,
      :host_value, :port_value, :path_values, :query_values,
      
      # built by: RequestMethods
      :method_value, :headers_values, :options_values, :accepts_values,
      
      # built by: CodecMethods
      :decoders_values, :encoder_search_value, :encoder_handler_value,
        
      # built by: ExtensionMethods
      :extensions_values, :operations_values, :subresources_values
      
    include UriMethods
    include RequestMethods
    include CodecMethods
    include ExtensionMethods
    include ConfigMethods
    
    # Configure our allowed builder methods.
    self.allowed_builder_methods = [
      :scheme, :ssl, :https, :user, :password, :host, :port, :path, :query, :reset_query,
      :http_method, :headers, :header, :reset_headers, :options, :option, :reset_options,
      :decoders, :encoder, :extending
    ].freeze
    
    def initialize(base)
      self.base_value = ::URI::Generic===base ? base.dup : URI(base) # compatibility with 1.9.2 and below
      self.path_values = []
      self.query_values = []
      self.headers_values = []
      self.accepts_values = []
      self.options_values = []
      self.decoders_values = []
      self.operations_values = []
      self.subresources_values = []
      self.extensions_values = []
      extract_from_base!
    end
    
    def to_resource
      self
    end

		def to_s
			to_url
		end
		
		def to_reflection(verb=method_value)
		  ResourceReflection.new(to_resource, verb)
		end
    
  protected

    # Builds client options, without a payload.
    def build_client_options(verb=build_http_method)
      build_options.merge method: verb, url: to_url, headers: build_headers
    end
    
  private
  
    # Separate userinfo and query from the base_value.
    def extract_from_base!(base=@base_value)
      self.user_value, self.password_value = base.user, base.password if base.userinfo
      query_values << base.query if base.query
      base.userinfo = base.query = nil
    end
  end
end

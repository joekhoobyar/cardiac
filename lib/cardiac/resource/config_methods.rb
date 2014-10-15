require 'active_support/concern'
require 'active_support/configurable'
require 'active_support/core_ext/hash/indifferent_access'
require 'net/http'

module Cardiac
  module ConfigMethods
    extend ActiveSupport::Concern

    include ActiveSupport::Configurable

    included do
      config_accessor :default_options
      self.default_options = {}.with_indifferent_access

      config_accessor :allowed_http_methods
      self.allowed_http_methods = Net::HTTP.constants.map{|k| Net::HTTP::const_get(k)::METHOD.downcase.to_sym rescue nil }.compact
      
      config_accessor :allowed_builder_methods
      
      config_accessor :unwrap_client_exceptions
      self.unwrap_client_exceptions = Cardiac::OperationHandler.unwrap_client_exceptions
      
      config_accessor :mock_response_on_connection_error
      self.mock_response_on_connection_error = Cardiac::OperationHandler.mock_response_on_connection_error
    end
    
    def reconfig
      config.clear ; config
    end
    
    def reconfigure
      config.clear ; configure
    end

  protected
  
    def build_config(base_config={})
      base_config.merge config
    end
  end
end
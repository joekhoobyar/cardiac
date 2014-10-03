require 'active_support/core_ext/object/blank'
require 'active_support/dependencies/autoload'
require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/delegation'

require 'cardiac/version'
require 'cardiac/errors'

module Cardiac
  extend ActiveSupport::Autoload
  
  # Utility classes.
  autoload_at 'cardiac/util' do
    autoload :RackUtils
    autoload :Proxy
    autoload :ExtensionBuilder
    autoload :Mixin
  end
  
  # Resources and builder DSL.
  autoload :Resource
  autoload_under 'resource' do
    autoload :Subresource
    autoload :UriMethods
    autoload :RequestMethods
    autoload :CodecMethods
    autoload :ExtensionMethods
    autoload :ConfigMethods
    autoload :ResourceBuilder, 'cardiac/resource/builder'
    autoload :ResourceAdapter, 'cardiac/resource/adapter'
  end
  autoload :Representation
  autoload_at 'cardiac/declarations' do
    autoload :DeclarationMethods
    autoload :DeclarationBuilder
    autoload :Declarations
  end
  
  # Operations and execution.
  autoload :Client
  autoload :OperationHandler
  autoload :OperationResult, 'cardiac/operation_handler'
  autoload :OperationBuilder
  autoload :OperationProxy, 'cardiac/operation_builder'
  autoload :LogSubscriber
  
  # Reflections, models and definitions.
  autoload_at 'cardiac/reflections' do
    autoload :BaseReflection
    autoload :ChainReflection
    autoload :ResourceReflection
    autoload :OperationReflection
  end
  autoload :Model
end

require 'cardiac/railtie' if defined? ::Rails

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.dirname(__FILE__) + '/cardiac/model/locale/en.yml'
end
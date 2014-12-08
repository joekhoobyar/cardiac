require 'active_support/dependencies/autoload'

module Cardiac
  module Model
    extend ActiveSupport::Autoload
    
    autoload :Attributes
    autoload :Base
    autoload :Callbacks
    autoload :Declarations
    autoload :Dirty
    autoload :Operations
    autoload :Persistence
    autoload :Querying
    autoload :Validations
    autoload :CacheDecoration
    
    autoload_at 'cardiac/model/factory_girl' do
      autoload :FactoryGirlRemoteStrategy
      autoload :FactoryGirlRemoteNotFoundStrategy
    end
  end
end

module Cardiac
  module Model
    # Cardiac::Model operational methods.
    module Operations
      extend ActiveSupport::Concern
      
      # Extensions that are applied to the OperationHandler. 
      module HandlerExtensions
        def transmit!(*args)
          super
        end
      end
      
      # Extensions that are applied to the ResourceAdapter.
      module AdapterExtensions
        def __codecs__
          @__codecs__ ||= Module.new{ include ::Cardiac::Representation::Codecs }
        end
      
        def __handler__
          @__handler__ ||= Class.new(::Cardiac::OperationHandler){ include HandlerExtensions; self }
        end
      end
      
      # Extensions that are applied to the OperationProxy.
      module ProxyExtensions
        def __adapter__
          @__adapter__ ||= Class.new(::Cardiac::ResourceAdapter){ include AdapterExtensions ; self }
        end
      end
      
      module ClassMethods
        
      private
        
        # All remote operations go through this method.
        def perform_operation(name, *args, &block)
          proxy = __operation_proxy__.new(base_resource)
          proxy.klass = self
          proxy.__send__(name,*args,&block)
        end

        def __operation_proxy__
          @__operation_proxy__ ||= Class.new(OperationProxy){ include ProxyExtensions ; self }
        end
      end
    end
  end
end

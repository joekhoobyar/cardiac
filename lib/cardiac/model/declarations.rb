module Cardiac
  module Model
    
    # Cardiac::Model declaration methods and resource extensions.
    module Declarations
      extend ActiveSupport::Concern
        
      # This extension block is used to build the base resource's extension module.
      RESOURCE_EXTENSION_BLOCK = Proc.new do
        
        ##
        # :method: find_instances
        # This member performs a GET, after merging any arguments into the query string.
        # This member is used by find(:all) and find_all
        operation :find_instances,     lambda{|*query|  query.any? ? query(*query).get : get }
          
        ##
        # :method: create_instance
        # This member performs a POST, using the given argument as the payload.
        # This member is used by create_record.
        operation :create_instance,    lambda{|payload| post(payload)     }
        
        ##
        # :method: identify
        # This member identifies a singular subresource by converting the given argument
        # to a parameter and appending it to the path.
        # This member is used by all query/persistence methods that operate on existing records.
        subresource :identify,         lambda{|id_or_model|   path(id_or_model.to_param) } do
          
          ##
          # :method: update_instance
          # This member performs a PUT, using the given argument as the payload.
          # This member is used by update_record.
          operation :update_instance,  lambda{|payload|       put(payload)      }
            
          ##
          # :method: delete_instance
          # This member performs a DELETE, after merging any arguments into the query string.
          # This member is used by delete and destroy.
          operation :delete_instance,  lambda{|*query|  query.any? ? query(*query).delete : delete }
            
          ##
          # :method: find_instance
          # This member performs a GET, after merging any arguments into the query string.
          # This member is used by find(:one), find(:some), find_one, find_some, and find_with_ids
          operation :find_instance,    lambda{|*query|  query.any? ? query(*query).get : get }
        end
      end

			include ::Cardiac::Declarations
			
			included do
			  singleton_class.alias_method_chain :base_resource=, :extensions
			  singleton_class.alias_method_chain :resource, :extensions
			end
    
			# Implement an instance's base resource as a subresource of the class base resource.
			# This prevents modifications to the subresource from persisting in the system.
			#
			# Persisted instances will use the +identify+ subresource, otherwise the base resource is used.
			def base_resource
			  Subresource.new persisted? ? self.class.identify(self) : self.class.base_resource
			end
      
      module ClassMethods
        
        # Overridden to extend the base resource with persistence operations.
        def base_resource_with_extensions=(base)
          case base
          when ::URI, ::String, ::Cardiac::Resource
            # Extend the resource with additional declarations before assigning it.
            base = DeclarationBuilder.new(base).extension_eval(&RESOURCE_EXTENSION_BLOCK)
          end    
          self.base_resource_without_extensions = base
        end
        
        # Overridden to ensure that the resource is first extended with persistence operations.
        def resource_with_extensions base=nil, &declaration
          self.base_resource = base if base.present?
          resource_without_extensions base_resource, &declaration
        end
      
      private
      
        # Internal method that checks for the presence of an extension method on the resource.
        def resource_has_extension_method?(name,base=base_resource)
          base && base.__extension_module__.method_defined?(name)
        end
        
        # FIXME: use a more optimized approach that falls back on method_missing.
        def respond_to_missing?(name,include_private=false)
          resource_has_extension_method?(name) || super 
        end
        
        # FIXME: use a more optimized approach that falls back on method_missing.
        def method_missing(name,*args,&block)
          if resource_has_extension_method? name
            perform_operation name, *args, &block
          else
            super
          end
        end
      end
    end
  end
end

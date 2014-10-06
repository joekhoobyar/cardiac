module Cardiac
  module Model
    
    # Cardiac::Model finder methods.
    # Some of this has been "borrowed" from ActiveRecord.
    module Querying
      extend ActiveSupport::Concern
        
      module ClassMethods
        
        # This is a basic implementation that just delegates to find_all.
        def all
          find_all
        end
        
        # Simple pattern for delegating find operations to the resource.
        # This is pretty similar to earlier AR versions that did not proxy to Relation.
        #
        # The biggest difference is that all finder methods accept an evaluator block
        # allowing bulk operations to be performed on returned results.
        def find(criteria=:all,*args,&evaluator)
          case criteria
          when :all, :first, :some, :one
            send(:"find_#{criteria}", *args, &evaluator)
          when Hash
            find_all(*args.unshift(criteria), &evaluator)
          when Array
            find_with_ids(criteria, &evaluator)
          when self, Numeric, String
            find_one(criteria, &evaluator)
          when Model::Base
            find_one(criteria.id, &evaluator)
          else
            raise ArgumentError, "unsupported finder criteria: #{criteria}:#{criteria.class}"
          end
        end
        
      protected
      
        # Simple pattern for delegating find :first operations to the resource.
        # Unlike the other finders, this one will return +nil+ instead of raising an error if it is not found.
        def find_first(criteria,*args,&evaluator)
          case criteria
          when Array
            criteria = criteria.first
          when self, Numeric, String
            # PASS-THROUGH
          when Model::Base
            criteria = criteria.id
          else
            raise ArgumentError, "unsupported find_first criteria: #{criteria}:#{criteria.class}"
          end 
          find_by_identity(criteria,&evaluator)
        end
        
        # Delegates to the find_instances operation on the resource.
        def find_all(*args, &evaluator)
          result = unwrap_remote_collection(find_instances(*args)) || []
          raise InvalidRepresentationError, 'expected Array, but got '+result.class.name unless Array===result
          result.map! do |record|
            instantiate(record, remote: true, &evaluator)
          end
        end

        # See ActiveRecord::Relation::FinderMethods#find_with_ids        
        def find_with_ids(*ids, &evaluator)
          expects_array = ids.first.kind_of?(Array)
          return ids.first if expects_array && ids.first.empty?
          ids = ids.flatten.compact.uniq
          case ids.size
          when 0
            raise RecordNotFound, "Couldn't find #{name} without an ID"
          when 1
            result = find_one(ids.first, &evaluator)
            expects_array ? [ result ] : result
          else
            find_some(ids, &evaluator)
          end
        end
        
        # See ActiveRecord::Relation::FinderMethods#find_one
        def find_one(id, &evaluator)
          record = find_by_identity(id,&evaluator)
          raise_record_not_found_exception!(id, 0, 1) unless record
          record
        end
        
        # See ActiveRecord::Relation::FinderMethods#find_some
        def find_some(ids, &evaluator)
          results = ids.map{|id| find_by_identity(id,&evaluator) }
          results.compact!
          raise_record_not_found_exception!(ids, results.size, expected_size) unless results.size == ids.size
          results
        end
      
        # @see ActiveRecord::Persistence#instantiate
        def instantiate(record, options = {})
          record = allocate.init_with options.merge('attributes'=>record).stringify_keys
          yield record if block_given?
          record
        end
        
        # See ActiveRecord::Relation::FinderMethods#raise_record_not_found_exception
        def raise_record_not_found_exception!(ids, result_size, expected_size) #:nodoc:
          if Array(ids).size == 1
            error = "Couldn't find #{name} with #{key_attributes.first}=#{ids}"
          else
            error = "Couldn't find all #{name.pluralize} with IDs "
            error << "(#{ids.join(", ")}) (found #{result_size} results, but was looking for #{expected_size})"
          end
          raise RecordNotFound, error
        end

        # Unwraps a collection payload returned by the remote.
        def unwrap_remote_collection(data,options={})
          unwrap_remote_data data, options
        end
        
      private
      
        # Delegates to the resource to find a single instance of a record and return the remote payload.
        def find_by_identity(id, &evaluator)
          record = unwrap_remote_data identify(id).find_instance
          instantiate(record, remote: true, &evaluator) if record
        rescue Cardiac::RequestFailedError => e
          raise e unless e.status == 404  # Ignores 404 Not Found
        end
      end
    end
  end
end
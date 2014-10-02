module Cardiac
  
  # Exception classes.
  class ProtocolError < StandardError
  end
  class ResourceError < StandardError
  end
  class UnresolvableResourceError < ResourceError
  end
  class InvalidOperationError < ResourceError
  end
  class InvalidRepresentationError < ResourceError
  end
  class OperationAbortError < ResourceError
  end
  class OperationFailError < ResourceError
  end
  
  # Thrown when a request has failed, due to a non-2xx status code.
  class RequestFailedError < ResourceError
    attr_reader :response
    def initialize(response,message=nil)
      @response = response
      super(message || Rack::Utils::HTTP_STATUS_CODES[@response.status])
    end
  end
  
  # @see ActiveRecord::RecordInvalid
  class RecordInvalid < ResourceError
    attr_reader :record # :nodoc:
    def initialize(record) # :nodoc:
      @record = record
      
      errors = @record.errors.full_messages.join(", ")
      remote_errors = @record.remote_errors.full_messages.join(", ")
      
      if remote_errors.present?
        remote_errors = "(previous remote operation) #{remote_errors}"
        errors += ' ' if errors.present?
      end
      
      super I18n.t(:"#{@record.class.i18n_scope}.errors.messages.record_invalid",
                   errors:        errors,
                   remote_errors: remote_errors,
                   default:       :"errors.messages.record_invalid")
    end
  end
    
  # @see ActiveRecord::RecordNotFound
  class RecordNotFound < OperationFailError
  end
  
  # @see ActiveRecord::RecordNotSaved
  class RecordNotSaved < OperationFailError
  end
  
  # @see ActiveRecord::RecordNotDestroyed
  class RecordNotDestroyed < OperationFailError
  end
  
  # @see ActiveRecord::ReadOnlyRecord
  class ReadOnlyRecord < OperationFailError
  end
  
end
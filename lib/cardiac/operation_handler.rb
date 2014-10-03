require 'active_support/configurable'
require 'active_support/rescuable'
require 'active_support/callbacks'

module Cardiac
  
  # This is what is returned by the OperationHandler.
  class OperationResult
    attr_accessor :response, :payload
    
    def initialize(handled, response, payload=nil)
      @transmitted = !! handled.transmitted?
      @completed   = !! handled.completed?
      @aborted     = !! handled.aborted?
      @response    = response
      @payload     = payload
    end
    
    def transmitted?; @transmitted end
    def completed?; @completed end
    def aborted?; @aborted end
  end
  
  # A base operation handler.
  class OperationHandler
    include ActiveSupport::Configurable
    include ActiveSupport::Rescuable
    include ActiveSupport::Callbacks
    
    rescue_from Errno::ETIMEDOUT, Errno::ECONNREFUSED, with: :service_unavailable
    rescue_from RequestFailedError, with: :unwrap_client_exception
    
    config_accessor(:unwrap_client_exceptions)          { false }
    config_accessor(:mock_response_on_connection_error) { true  }
      
    define_callbacks :transmission, :abort, :complete
    
    DEFAULT_RESPONSE_HANDLER = Proc.new do |response|
      raise RequestFailedError, response unless response.successful?
      response
    end
    
    attr_accessor :verb, :url, :headers, :payload, :options, :response_handler, :result
    
    def initialize client_options, payload=nil, &response_handler
      @verb = client_options[:method] or raise InvalidOperationError, 'no HTTP verb was specified'
      @url = client_options[:url] or raise InvalidOperationError, 'no URL was specified'
      @headers = client_options[:headers]
      @payload = payload
      @options = client_options.except(:method, :url, :headers)
      @response_handler = response_handler || DEFAULT_RESPONSE_HANDLER
    end
    
    def transmit!
      # Reset any old state before actually performing the transmission.
      self.result = @aborted = @transmitted = nil
      
      # Perform the actual request and receive the response.
      run_callbacks :transmission do
        self.result = nil
        begin
          self.result = @response_handler.call(perform_request)
          
          # A response was received, so consider it transmitted.
          @transmitted = true
        rescue Exception => exception
          
          # An exception was received, so consider it untransmitted.
          @transmitted = false
          
          # The exception may still be handled, to prevent the operation from aborting.
          abort! exception
        end
      end
      
      # If we get here, then we must have a result to return.
      complete!
      
    ensure
      # Always clear out our result instance before returning it.
      self.result = nil
    end
    
    # Checks if the request was transmitted and a response was received.
    def transmitted?
      @transmitted
    end
    
    # Checks if the operation was aborted due to an exception being thrown.
    # Even though this does not involve the interpretation a response body, an
    # aborted transmission could instead be considered completed by handling the exception.
    def aborted?
      @aborted
    end
    
    # Checks if the operation was completed.
    # This means that either the operation was transmitted, or an exception was handled successfully.
    def completed?
      @aborted.nil? ? @transmitted : !@aborted
    end

  protected
  
    def abort! exception
      # Start out by assuming we will abort.
      @aborted = true
      
      # Now we can run the abort callbacks.
      run_callbacks :abort do
        if rescue_with_handler(exception)
          @aborted = false
          raise OperationAbortError
        elsif Exception===result
          self.result, exception = nil, self.result
        end
      end
      
      # Now we can re-raise the unhandled exception.
      raise exception
      
    rescue OperationAbortError => e
      raise e if exception == e # just in case
    end
    
    # Performs the completion of an operation, returning an OperationResult
    def complete!(response=self.result)
      run_callbacks :complete do
        OperationResult.new(self, response)
      end
    end
  
    # Customized to only consider an exception handler successful if and only if
    # it sets a result on this instance that is not itself an Exception.
    def rescue_with_handler exception
      if handler = handler_for_rescue(exception)
        self.result = handler.arity != 0 ? handler.call(exception) : handler.call
        
        # Fail if the result is missing or is an Exception.
        result.present? && ! result.is_a?(Exception)
      end
    end
    
  private
  
    def perform_request
      Client.request @verb.to_s.upcase, @url.to_s, @headers.try(:stringify_keys) || {}, @payload
    end
  
    # Handles RequestFailedError exceptions, optionally unwrapping them.
    # This is a special case since we must still show that the operation was "transmitted"
    # even if we will be aborting this operation.
    def unwrap_client_exception e
      # If we receive a "wrapped" exception, then a response was definitely received.
      # However, the operation will still abort unless we are unwrapping client exceptions since
      # any user-supplied exception handler would have overridden this one.
      #
      # Thus, we will set this flag early so that even an unhandled client exception that
      # aborts the operation will still correctly show that the response was transmitted.
      @transmitted = true
      
      # The configuration determines if we should use a non-20x response as a result.
      self.result = e.response if unwrap_client_exceptions && e.respond_to?(:response)
    end

    # Handles I/O exceptions and other similar cases that do not involve the HTTP protocol.
    # Optionally, these conditions could also be made to provide a mock response on a connection error.
    # This would prevent the operation from aborting but still show that the response was not transmitted.
    def service_unavailable e
      self.result = Client.build_mock_response e, '503' if mock_response_on_connection_error
    end
  end
end
module Cardiac
  module Model
    
    # Cardiac::Model cache decoration methods.
    module CacheDecoration
      extend ActiveSupport::Concern
      
      module ClassMethods
        
        # The callback to be installed on the adapter.
        MODEL_CACHE_CONTROL_PROC = Proc.new{|adapter| adapter.klass._model_cache_control(adapter.response) }
        
        # Causes all find(..) methods to go through an object-level cache,
        # which is populated on demand whenever it is needed.
        #
        # Pass +false+ to uninstall the model cache.
        def cache_all! options={}
          if options
            @_model_cache_control = (Hash===options ? options : {}).update(expires_at: Time.now)
            __operation_proxy__.__adapter__.after_execute MODEL_CACHE_CONTROL_PROC
          else
            @model_cache = @_model_cache_control = nil
            __operation_proxy__.__adapter__.skip_callback :execute, :after,  MODEL_CACHE_CONTROL_PROC
          end
        end
        
        # Internal method that controls the model cache, using the given response object.
        def _model_cache_control(response)
          response = Rack::Cache::Response.new(*response.to_a)
          if response.fresh?
            @_model_cache_control[:expires_at] = response.expires || (response.date + response.ttl)
          else
            @_model_cache_control[:expires_at] = Time.now
          end
        end
    
      protected
        
        # Override this internal method to use a local model cache for retrieving all instances.
        def find_all(*args, &evaluator)
          unless @_model_cache_control
            super
          else
            if @model_cache.nil? || @_model_cache_control[:expires_at].past?
              result = super(*args)
              sort_by = @_model_cache_control[:sort_by] and result.sort_by!(&sort_by)
              @model_cache = Hash[result.map{|record| record.readonly! ; record.freeze ; [record.id.to_s, record] }]
            end
            evaluator ? @model_cache.values.each(&evaluator) : @model_cache.values
          end
        end
        
      private
        
        # Override this internal method utilize a market cache for retrieving single instances.
        # TODO: This should not require knowledge of Model::Base internals.
        #
        # @see Cardiac::Model::Querying
        def find_by_identity(id, &evaluator)
          unless @_model_cache_control
            super
          else
            find_all if @model_cache.nil? || @_model_cache_control[:expires_at].past?
            record = @model_cache[id.to_s] unless id.nil?
            evaluator.call(record) if evaluator
            record
          end
        end  
      end 
        
    end
  end
end

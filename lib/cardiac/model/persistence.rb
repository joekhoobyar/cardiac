module Cardiac
  module Model
    
    # Cardiac::Model persistence methods.
    # Most of this has been "borrowed" from ActiveRecord.
    module Persistence
      extend ActiveSupport::Concern
        
      module ClassMethods
        # See ActiveRecord::Base.create
        def create(attributes = nil, &block)
          if attributes.is_a?(Array)
            attributes.collect { |attr| create(attr, &block) }
          else
            object = new(attributes, &block)
            object.save
            object
          end
        end
        
      end
      
      # Returns true if this object hasn't been saved yet -- that is, a record
      # for the object doesn't exist in the data store yet; otherwise, returns false.
      def new_record?
        @new_record
      end
  
      # Returns true if this object has been destroyed, otherwise returns false.
      def destroyed?
        @destroyed
      end
  
      # Returns true if the record is persisted, i.e. it's not a new record and it was
      # not destroyed, otherwise returns false.
      def persisted?
        !(new_record? || destroyed?)
      end
      
      # Performs a DELETE on the remote resource if the record is not new, marks it
      # as destroyed, then freezes the attributes.
      def delete
        delete_record
        freeze
      end
      
      # Delegates to delete, except it raises a +ReadOnlyRecord+ error if the record is read-only.
      def destroy
        raise ReadOnlyRecord if readonly?
        delete
      end
      
      # Delegates to destroy, but raises +RecordNotDestroyed+ if checks fail.
      def destroy!
        destroy || raise(RecordNotDestroyed)
      end      
      
      # Delegates to create_or_update, but rescues validation exceptions to return false.
      def save(*)
        create_or_update
      rescue RecordInvalid
        false
      end

      # Delegates to create_or_update, but raises +RecordNotSaved+ if validations fail.
      def save!(*)
        create_or_update || raise(RecordNotSaved)
      end
  
      # Reloads the attributes of this object from the remote.
      # Any (optional) arguments are passed to find when reloading.
      def reload(*args)
        fresh_object = self.class.find(self.id, *args)
        @attributes.update(fresh_object.instance_variable_get('@attributes'))
        self
      end
      
      # Updates a single attribute and saves the record.
      # This is especially useful for boolean flags on existing records. Also note that
      #
      # * Validation is skipped.
      # * Callbacks are invoked.
      # * updated_at/updated_on column is updated if that column is available.
      # * Updates all the attributes that are dirty in this object.
      #
      # This method raises an +OperationFailError+ if the attribute is marked as readonly.
      def update_attribute(name, value)
        name = name.to_s
        verify_readonly_attribute(name)
        send("#{name}=", value)
        save(validate: false)
      end
  
      # Updates the attributes of the model from the passed-in hash and saves the
      # record. If the object is invalid, the saving will fail and false will be returned.
      def update(attributes)
        assign_attributes(attributes)
        save
      end
  
      alias update_attributes update
  
      # Updates its receiver just like +update+ but calls <tt>save!</tt> instead
      # of +save+, so an exception is raised if the record is invalid.
      def update!(attributes)
        assign_attributes(attributes)
        save!
      end
  
      alias update_attributes! update!
  
    private
    
      # Internal method that deletes an existing record, then marks this record as destroyed.
      def delete_record
        self.remote_attributes = self.class.identify(self).delete_instance if persisted?
        @destroyed = true
      end

      # Internal method that either creates a new record, or updates an existing one.
      # Raises a ReadOnlyRecord error if the record is read-only.
      def create_or_update
        raise ReadOnlyRecord if readonly?
        result = new_record? ? create_record : update_record
        result != false
      end
      
      # Internal method that updates an existing record.
      def update_record(attribute_names = attributes.keys)
        
        # Build a payload hash, but silently skip this operation if they are empty.
        payload_hash = attributes_for_update(attribute_names)
        return unless payload_hash.present?
        
        # Perform the operation and save the attributes returned by the remote.
        self.remote_attributes = self.class.identify(self).update_instance(payload_hash)
        
        # Return success.
        true
      end
  
      # Internal method that creates an existing record.
      def create_record(attribute_names = @attributes.keys)
        
        # Build a payload hash.
        payload_hash = attributes_for_create(attribute_names)
        
        # Perform the operation and save the attributes returned by the remote.
        self.remote_attributes = self.class.create_instance(payload_hash)
        
        # Write back any key attributes returned by the remote.
        self.class.key_attributes.each do |key| key = key.to_s
          write_attribute key, @remote_attributes[key] if @remote_attributes.has_key? key
        end
 
        # No longer a new record, if we at least have all key attributes defined.
        @new_record = ! self.class.key_attributes.all?{|key| query_attribute key }
          
        # Return success, if we are no longer a new record.
        ! @new_record
      end

      # @see ActiveRecord::Persistence#verify_readonly_attribute
      def verify_readonly_attribute(name)
        raise OperationFailError, "#{name} is marked as readonly" if self.class.readonly_attributes.include?(name)
      end
    end
  end
end
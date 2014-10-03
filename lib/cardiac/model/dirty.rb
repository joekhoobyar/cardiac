module Cardiac
  module Model
    # Cardiac::Model dirty attribute methods.
    # Some of this has been "borrowed" from ActiveRecord.
    module Dirty
      extend ActiveSupport::Concern

      include ActiveModel::Dirty

      included do
        class_attribute :partial_updates
        self.partial_updates = false     # Off by default, unlike ActiveRecord.
      end

      # Attempts to +save+ the record and clears changed attributes if successful.
      #
      # @see ActiveRecord::Dirty#save
      def save(*) #:nodoc:
        if status = super
          @previously_changed = changes
          @changed_attributes.clear
        end
        status
      end

      # Attempts to <tt>save!</tt> the record and clears changed attributes if successful.
      #
      # @see ActiveRecord::Dirty#save!
      def save!(*) #:nodoc:
        super.tap do
          @previously_changed = changes
          @changed_attributes.clear
        end
      end

      # <tt>reload</tt> the record and clears changed attributes.
      #
      # @see ActiveRecord::Dirty#reload
      def reload(*) #:nodoc:
        super.tap do
          @previously_changed.clear
          @changed_attributes.clear
        end
      end
      
      private

      # Wrap write_attribute to remember original attribute value.
      #
      # Very similar to ActiveRecord::Dirty, except that we are not dealing with timezones.
      # The semantics of ActiveModel::Dirty#attribute_will_change! does not handle attributes
      # changing _back_ to their original value.  Thus, like ActiveRecord, we won't use it.
      #
      # @see ActiveRecord::Dirty#write_attribute
      def attribute=(attr, value)
        attr = attr.to_s

        # The attribute already had an unsaved change, so check if it is changing back to the original.
        if attribute_changed?(attr)
          old = @changed_attributes[attr]
          @changed_attributes.delete(attr) unless _field_changed?(attr, old, value)

          # No existing unsaved change, so simply remember this value if it differs from the original.
        else
          old = clone_attribute_value(:read_attribute, attr)
          @changed_attributes[attr] = old if _field_changed?(attr, old, value)
        end

        super(attr, value)
      end

      # Wrap update_record to perform partial updates when configured to do so.
      #
      # @see ActiveRecord::Dirty#update
      def update_record(*)
        if partial_updates?
          super(changed)
        else
          super
        end
      end

      # Very similar to ActiveRecord::Dirty, except that we use ActiveAttr::Typecasting instead of columns.
      # If no type is available, then just compare the values directly.
      #
      # @see ActiveRecord::Dirty#_field_changed?
      def _field_changed?(attr, old, value)
        if type = _attribute_type(attr)
          if Numeric === type && (changes_from_nil_to_empty_string?(old, value) || changes_from_zero_to_string?(old, value))
            value = nil
          else
            value = typecast_attribute(_attribute_typecaster(attr), value)
          end
        end
        old != value
      end

      # @see ActiveRecord::Dirty#changes_from_nil_to_empty_string?
      def changes_from_nil_to_empty_string?(old, value)
        # If an old value of 0 is set to '' we want this to get changed to nil as otherwise it'll
        # be typecast back to 0 (''.to_i => 0)
        (old.nil? || old == 0) && value.blank?
      end

      # @see ActiveRecord::Dirty#changes_from_zero_to_string?
      def changes_from_zero_to_string?(old, value)
        # For fields with old 0 and value non-empty string
        old == 0 && value.is_a?(String) && value.present? && value != '0'
      end
    end
  end
end
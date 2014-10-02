module Cardiac
  module Model
    
    # Cardiac::Model finder methods.
    # Most of this has been "borrowed" from ActiveRecord.
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Validations
      
      included do
        
        ##
        # :method: remote_errors_class=
        # Set this on your class to customize the errors instance to build.
        # The default value is ::ActiveModel::Errors
        class_attribute :remote_errors_class
      end
    
      module ClassMethods
        
        def create!(attributes = nil, &block)
          if attributes.is_a?(Array)
            attributes.collect { |attr| create!(attr, &block) }
          else
            object = new(attributes)
            yield(object) if block_given?
            object.save!
            object
          end
        end
      end
      
      def save(options={})
        perform_validations(options) && super && remote_errors.empty?
      end
    
      def save!(options={})
        raise RecordInvalid.new(self) unless perform_validations(options)
        super
      ensure
        raise RecordInvalid.new(self) unless remote_errors.empty?
      end
    
      # Runs all the validations within the specified context. Returns +true+ if
      # no errors are found, +false+ otherwise.
      #
      # If the argument is +false+ (default is +nil+), the context is set to <tt>:create</tt> if
      # <tt>new_record?</tt> is +true+, and to <tt>:update</tt> if it is not.
      #
      # Validations with no <tt>:on</tt> option will run no matter the context. Validations with
      # some <tt>:on</tt> option will only run in the specified context.
      def valid?(context = nil)
        context ||= (new_record? ? :create : :update)
        output = super(context)
        errors.empty? && output
      end
        
      # Stores the errors returned by the remote, after performing any unpacking/decoding.
      # To customize the options used to add the error:
      #
      #   <code>assign_remote_errors(data,options: {foo: :bar})</code>
      #
      def assign_remote_errors(data,options={})
        decode_remote_errors(data,options).each do |key,values|
          Array.wrap(values).each do |value|
            remote_errors.add key, value.to_s, *([options[:options]] if Hash===options[:options])
          end
        end
      end
      
      alias remote_errors= assign_remote_errors
        
      # Like ActiveModel::Validations#errors, but used for remote errors.
      def remote_errors
        @remote_errors ||= (self.class.remote_errors_class || ::ActiveModel::Errors).new(self)
      end
    
    protected
    
      # Like ActiveModel::Validations#perform_validations, but also checks remote_errors.
      #
      # Remote_errors are not cleared before execution, but you could easily do that in a callback:
      #
      #   <code>before_validation { remote_errors.clear }</code>
      #
      def perform_validations(options={})
        options[:validate] == false || (valid?(options[:context]) && remote_errors.empty?)
      end
    
      # Overridden to unpack remote errors from the data.
      def decode_remote_attributes(data,options={})
        self.remote_errors = data.delete('errors')
        super
      end
      
      # Decodes errors returned by the remote.
      #
      # If the remote did not return a Hash, the data is wrapped in a single key: <code>:base</code>
      # If no remote errors are present, an empty Hash is returned.
      def decode_remote_errors(data, options={})
        data.present? ? (Hash===data ? data : {base: data}) : {}
      end
  
    private
    
      # Overridden to set @new_record back to true if there are remote errors.
      def create_record
        super
        @new_record ||= ! remote_errors.empty?
          
        # Return success, if we are no longer a new record.
        ! @new_record
      end
    
      # Overridden to set @destroyed back to false if there are remote errors.
      def delete_record
        super
        @destroyed &&= remote_errors.empty?
      end
      
    end

  end
end
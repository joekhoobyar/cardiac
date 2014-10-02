module Cardiac
  module Model
    
    # Cardiac::Model attribute methods.
    # Some of this has been "borrowed" from ActiveRecord.
    module Attributes
      extend ActiveSupport::Concern
      
      module ClassMethods
      
        # Overridden to support passing in aliases at the same time.
        # This could decrease the code size for attributes declarations by almost 50% for models with
        # non-friendly remote attribute names.
        def attribute(name,options={})
          aliases = Array(options[:aliases])
          super name, options.except(:aliases)
          aliases.each{|k| alias_attribute k, name } if aliases
        end

      protected
              
        # Unwraps a payload returned by the remote, requiring it to be present.
        #
        # Callers could pass <code>{allow_empty: true}</code> in the options to prevent
        # empty results from being converted to <code>nil</code>.
        def unwrap_remote_data(data,options={})
          data = data.values.first if Hash===data && data.keys.size==1 && data.keys.first.to_s!='errors'
          data = data.presence unless options[:allow_empty]
          data
        end
      end
      
      included do
        class_attribute :readonly_attributes, instance_writer: false
        class_attribute :key_attributes, instance_writer: false
        class_attribute :id_delimiter
        
        self.readonly_attributes = []
        self.key_attributes = [:id]
        self.id_delimiter = '-'
      end
    
      # Retrieves the most recently unpacked/decoded remote attributes.
      def remote_attributes
        @remote_attributes.with_indifferent_access
      end
      
      # Overridden to use this model's key_attributes to build the key.
      # Returns an array of the key values, if they are all present, otherwise, returns nil.
      def to_key
        keys = key_attributes.presence and keys.map do |key|
          return unless query_attribute(key)
          read_attribute(key)
        end
      end
      
      # This baseline implementation uses this model's id_delimiter to join what is returned by to_key.
      # If the id_delimiter is set to nil, it will simply return an array instead.
      #
      # NOTE: Defining an :id attribute on your model will override this implementation.
      def id
        delim, values = id_delimiter, to_key
        (delim && values) ? values.join(delim) : values
      end
      
    protected

      # Stores the attributes returned by the remote, after performing any unpacking/decoding.
      def assign_remote_attributes(data,options={})
        @remote_attributes = Hash[
          decode_remote_attributes(unwrap_remote_attributes(data, options), options).map do |key,value|
            [key, value.duplicable? ? value.clone : value]
          end
        ]
      end
      
      alias remote_attributes= assign_remote_attributes
  
      # Returns a copy of this model's attributes, cloning the duplicable values.
      def clone_attributes(reader_method = :read_attribute, attributes = {}) # :nodoc:
        attribute_names.each do |name|
          attributes[name] = clone_attribute_value(reader_method, name)
        end
        attributes
      end
  
      # Reads an attribute value and returns a clone, if it is duplicable, or the original value, if not.
      def clone_attribute_value(reader_method, attribute_name) # :nodoc:
        value = send(reader_method, attribute_name)
        value.duplicable? ? value.clone : value
      rescue TypeError, NoMethodError
        value
      end

      # Unwraps attributes returned by the remote, requiring the data to be non-empty.
      #
      # Callers could pass <code>{allow_empty: true}</code> in the options to prevent
      # empty results from being converted to <code>nil</code>.
      #
      # NOTE: The baseline implementation just delegates to the class method: unwrap_remote_data
      def unwrap_remote_attributes(data,options={})
        self.class.send :unwrap_remote_data, data, options
      end
      
      # Decodes attributes returned by the remote, requiring the data to be non-nil.
      # Callers could pass <code>{only: ...}</code> or <code>{except: ...}</code> in the options
      # to filter the attributes by key.
      #
      # If the remote did not return a Hash, the data is first wrapped in a single key: <code>:data</code>
      def decode_remote_attributes(data,options={})
        unless data.nil?
          data = Hash===data ? data.with_indifferent_access : {data: data}
          data = data.slice(*options[:only]) if options[:only]
          data = data.except(*options[:except]) if options[:except]
        end
        data
      end

    private
      
      # Filters the primary keys and readonly attributes from the attribute names.
      def attributes_for_update(attribute_names)
        attributes.slice(*attribute_names).except(*(readonly_attributes+key_attributes))
      end
  
      # Filters out the primary keys, from the attribute names, when the primary
      # key is to be generated (e.g. the id attribute has no value).
      def attributes_for_create(attribute_names)
        attributes.slice(*attribute_names).except(*key_attributes.reject{|k| query_attribute(k) })
      end
  
      def readonly_attribute?(name)
        self.class.readonly_attributes.include?(name)
      end
  
      def key_attribute?(name)
        self.class.key_attributes.include?(name)
      end
  
      # No seralized attribute support yet.
      def serialized_attribute_value(name)
        read_attribute(name)
      end
    end
  end
end
require 'active_support/core_ext/hash/indifferent_access'
require 'active_attr'

module Cardiac
  module Model
    class Base
      extend Cardiac::ResourceCache::ClassMethods
      
      include ActiveAttr::Model
      include Cardiac::Model::Attributes
      include Cardiac::Model::Querying
      include Cardiac::Model::Persistence
      include Cardiac::Model::Validations
      include Cardiac::Model::Dirty
      include Cardiac::Model::Callbacks
      include Cardiac::Model::Declarations
      include Cardiac::Model::Operations
      include Cardiac::Model::CacheDecoration
      include ActiveSupport::Configurable
      
      # Instances may not explicitly define their own base resource.
      undef_method :resource if method_defined? :resource
			
      # Expose instance-level with_resource since there is a useful instance-level implementation of base_resource.
      public :with_resource
      
      config_accessor :operation_context
      self.operation_context = {}.with_indifferent_access
      
      # @see ActiveRecord::Core
      mattr_accessor :logger, instance_writer: false
      
      # Configure whether or not to treat all instances as read-only.
      class_attribute :readonly, instance_writer: false
      
      # Subclasses have an internationalization scope separate from active model.
      def self.i18n_scope
        :cardiac_model
      end
      
      # @see ActiveRecord::Core#initialize
      def initialize(attributes = nil, options = {})
        super
        init_internals
        init_changed_attributes
        run_callbacks :initialize unless _initialize_callbacks.empty?
      end

      # @see ActiveRecord::Core#init_with
      def init_with(coder)
        _remote = coder['remote']
        self.attributes = _remote ? {} : coder['attributes']
        init_internals
        @new_record = false
        if _remote
          _remote = {} unless Hash===_remote
          self.attributes = decode_remote_attributes( unwrap_remote_attributes(coder['attributes'], _remote),
                                                      _remote )
          @changed_attributes.clear
        end
        run_callbacks :find
        run_callbacks :initialize
        self
      end
      
      # @see ActiveRecord::Core#slice
      def slice(*methods)
        Hash[methods.map { |method| [method, public_send(method)] }].with_indifferent_access
      end
      
      # @see ActiveRecord::Core#inspect
      def inspect
        defined?(@attributes) && @attributes ? super : "#<#{self.class} not initialized>"
      end
      
      # @see ActiveRecord::Core#encode_with
      def encode_with(coder)
        coder['attributes'] = attributes
      end

      # @see ActiveRecord::Core#==
      def ==(comparison_object)
        super ||
          comparison_object.instance_of?(self.class) &&
          id.present? &&
          comparison_object.id == id
      end
      alias :eql? :==

      # @see ActiveRecord::Core#hash
      def hash
        id.hash
      end

      # @see ActiveRecord::Core#freeze
      def freeze
        @attributes = @attributes.clone.freeze
        self
      end

      # @see ActiveRecord::Core#frozen
      def frozen?
        @attributes.frozen?
      end

      # @see ActiveRecord::Core#<=>
      def <=>(other_object)
        if other_object.is_a?(self.class)
          self.to_key <=> other_object.to_key
        end
      end

      # @see ActiveRecord::Core#readonly?
      def readonly?
        @readonly
      end

      # @see ActiveRecord::Core#readonly!
      def readonly!
        @readonly = true
      end
      
    private

      # @see ActiveRecord::Core#init_changed_attributes
      def init_changed_attributes
        attribute_defaults.each do |name,value|
          @changed_attributes[name] = value if _field_changed?(name, value, @attributes[name])
        end
      end

      # Under Ruby 1.9, Array#flatten will call #to_ary (recursively) on each of the elements
      # of the array, and then rescues from the possible NoMethodError. If those elements are
      # ActiveRecord::Base's, then this triggers the various method_missing's that we have,
      # which significantly impacts upon performance.
      #
      # So we can avoid the method_missing hit by explicitly defining #to_ary as nil here.
      #
      # See also http://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
      def to_ary # :nodoc:
        nil
      end

      # @see ActiveRecord::Core#init_internals
      def init_internals
        @attributes ||= {}
          
        self.class.key_attributes.each do |key|
          @attributes[key] = nil unless @attributes.key?(key)
        end

        @previously_changed       = {}
        @changed_attributes       = {}
        @readonly                 = !! self.class.readonly?
        @destroyed                = false
        @new_record               = true
        @remote_attributes        = {}
      end
    end
    
    ActiveSupport.run_load_hooks(:cardiac_model, Base)
  end

end

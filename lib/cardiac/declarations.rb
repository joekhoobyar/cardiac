module Cardiac
  class DeclarationBuilder < ::Cardiac::ExtensionBuilder
    # Overridden to build directly on a resource/subresource.
    def initialize(base, extension_module=nil)
      case base
      when ::Cardiac::Resource
        builder = ::Cardiac::Subresource.new(base)
      when ::URI, ::String
        builder = ::Cardiac::Resource.new(base)
      else
        raise ::ArgumentError, 'a base URI or Resource must be provided'
      end
      super builder, extension_module
    end

    # Overridden to return an extended resource/subresource,
    # but skip building the extension module if no block is given.
    def extension_exec(*args, &block)
      if block
        super(*args, &block)
        @builder.extending(__extension_module__)
      end
      @builder
    end
  end

  module DeclarationMethods
    
    # Declares a new resource off of the given base, using the given extension block.
    def resource base, &declaration
      DeclarationBuilder.new(base).extension_eval(&declaration)
    end
  
    # Dynamically declares a new subresource (optionally targetting a given sub-url),
    # and yields a new OperationProxy which targets that subresource.
    def with_resource(at=nil)
      yield OperationProxy.new(at ? Subresource.new(base_resource).at(at) : base_resource)
    end
  end
  
  module Declarations
    extend ActiveSupport::Concern
    
    included do
      if respond_to? :class_attribute
        class_attribute :base_resource, instance_reader: false, instance_writer: false
      else
        mattr_accessor :base_resource, instance_reader: false, instance_writer: false
      end
    end
    
    # Extensions for a class or even a module, so it may declare resources.
    module ClassMethods
      include DeclarationMethods
      
      delegate :base_url, to: :base_resource
    
      # Overridden to always write to the base_resource
      def resource base=base_resource, &declaration
        self.base_resource = super(base, &declaration)
      end
    end
    
    # Instance-level extensions for declaring resources.
    include DeclarationMethods
    
    # These start out as private, especially since an instance-level :with_resource
    # would need an instance-level implementation of :base_resource
    private :resource, :with_resource
  end

end
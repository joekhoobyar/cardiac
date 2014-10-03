require 'rack/utils'
require 'active_support/builder'
require 'blankslate'

module Cardiac
  
  # Specialized version(s) of Rack utility functions.
  module RackUtils
    include ::Rack::Utils
    
    # Overridden to work with false, true and nil, and otherwise call :to_param on single values that are not strings.
    def build_nested_query(value,prefix=nil)
      case value
      when Hash, Array, String
        super
      when TrueClass
        "#{prefix}=true"
      when FalseClass
        "#{prefix}=false"
      when NilClass
        "#{prefix}="
      else
        super value.to_param, prefix
      end
    end
  end
  
  # Base proxy class.
  #
  # On Ruby 2.0 and above, we can use ActiveSupport's ProxyObject, otherwise we must use BlankSlate.
  class Proxy < (RUBY_VERSION>='2.0' && defined?(::ActiveSupport::ProxyObject) ? ::ActiveSupport::ProxyObject : ::BlankSlate)
    
    # We at least would like some basics here.
    %w(kind_of? is_a? inspect class method send).each do |k|
      define_method k, ::Kernel.instance_method(k)
    end
    %w(class extend send object_id public_send).each do |k|
      define_method :"__#{k}__", ::Kernel.instance_method(k)
    end

    # By default, do not advertise methods on this proxy object.     
    def respond_to?(name,include_all=false)
      respond_to_missing?(name,include_all)
    end
  end
  
  # A specialized proxy class for building extension modules while supporting method_missing.
  class ExtensionBuilder < Proxy
    def initialize(builder,extension_module=nil)
      @builder = builder
      @extension_module = extension_module
    end
    
    # Performs a :module_eval on the extension module,
    # temporarily defining :method_missing on it's singleton class for the duration of the block.
    def extension_eval(&block)
      extension_exec(&block)
    end

    # Performs a :module_eval or :module_exec on the extension module,
    # temporarily defining :method_missing on it's singleton class for the duration of the block.
    def extension_exec(*args, &block)
      orig_missing = build_method_missing
      begin
        args.empty? ? __extension_module__.module_eval(&block) : __extension_module__.module_exec(*args,&block)
      ensure
        __extension_module__.singleton_class.send(:remove_method, :method_missing)
        __extension_module__.define_singleton_method :method_missing, orig_missing if orig_missing
      end
      @builder
    end
    
    # Lazily creates the extension module.
    def __extension_module__
      @extension_module ||= ::Module.new
    end

  protected

    # Called to build a :method_missing implementation on the extension module.
    def build_method_missing
      if __extension_module__.singleton_methods(false).include?(:method_missing)
        orig = __extension_module__.method(:method_missing)
      end
      self.class.build_method_missing(self)
      orig
    end
    
    # This method's arguments are minimal closure needed to build :method_missing.
    # The instance version of this method delegates here.
    def self.build_method_missing(adapter)
      # NOTE: Your editor may not like the |name,*args,&block| syntax below. Ignore any errors it reports.
      adapter.__extension_module__.define_singleton_method :method_missing do |name,*args,&block|
        if adapter.respond_to?(name)
          adapter.__send__(name, *args, &block)
        else
          super(name, *args, &block)
        end
      end
    end
    
  private
  
    # Delegates to the builder.
    def respond_to_missing?(name,include_private=false)
      @builder.respond_to?(name, include_private)
    end
    
    # Delegates to the builder, saves it's return value as the new builder, and returns self.
    def method_missing(name, *args, &block)
      if @builder.respond_to?(name)
        @builder = @builder.__send__(name, *args, &block)
        self
      else
        super
      end
    end
  end
  
  begin
    # AS 4.0+
    require 'active_support/per_thread_registry'
    PerThreadRegistry = ::ActiveSupport::PerThreadRegistry
  rescue LoadError
    # AS 3.2
    module PerThreadRegistry
    protected
      def method_missing(name, *args, &block)
        define_singleton_method(name) do |*a, &b|
          per_thread_registry_instance.public_send(name, *a, &b)
        end
        send(name, *args, &block)
      end
    private
      def per_thread_registry_instance
        Thread.current[name] ||= new
      end
    end
  end
 
end
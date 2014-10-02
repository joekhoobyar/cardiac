require 'mime/types'
require 'uri'
require 'active_support/core_ext/object/to_param'
require 'active_support/core_ext/object/to_query'
require 'rack/utils'
require 'multi_json'

module Cardiac
  module Representation
    
    # Looking up coders, mimes, etc.
    module LookupMethods
      def coder_for(search)
        search = $1.to_s.classify if search =~ /\.?([a-z][a-z0-9_]*)$/i
        const_get search.to_s
      end

      def mime_types(options={})
        options[:types] || MIME::Types
      end

      def mimes_for(search, options={})
        options = {complete: true, platform: false}.merge!(options)
        case search
        when /\.?([^\/\.])$/
          mime_types(options).of(search.to_s, options[:platform])
        when Symbol
          mime_types(options)[search.to_s, options]
        else
          mime_types(options)[search, options]
        end
      end
    end

    # Basic reflection of a representation type.
    class Reflection < Struct.new(:extension, :types, :default_type, :coder)
      def initialize(extension,default_type=nil,*extra_types)
        types = __codecs__.mimes_for(extension) + extra_types
        if default_type.nil?
          default_type = types.first
        elsif ! types.include? default_type
          types.unshift default_type
        end
        super extension.to_sym, types, default_type, __codecs__.coder_for(extension)
      end
      
      delegate :coder_for, :mimes_for, to: :__codecs__
      private :coder_for, :mimes_for
      
      def matches?(mime_type)
        types.any?{|type| type.like? mime_type}
      end
    
      def __codecs__
        @__codecs__ ||= ::Cardiac::Representation::Codecs
      end
    end

    module Codecs
      extend LookupMethods
      
      module FormEncoded
      module_function
      
        def encode(value,options={})
          String===value ? value : URI.encode_www_form(value)
        end

        def decode(value,options={})
          Hash===value ? value.stringify_keys : Hash[URI.decode_www_form(value)]
        end
      end
      
      module UrlEncoded
        
        # In Ruby 1.9.3, super is not available from module_function(s).
        # It is simplest to just define all extensions here, then.
        module Extensions
          include ::Cardiac::RackUtils
          include FormEncoded
          alias encode_form encode
          alias decode_form decode
        end
        
        include Extensions
        extend Extensions
        
      module_function
      
        def encode(value,options={})
          Hash===value ? build_nested_query(value) : encode_form(value)
        end

        def decode(value,options={})
          decode_form(value).inject({}) do |params,(key,value)|
            normalize_params params, key, value
          end
        end
      end

      module Json
        module_function
        def encode(value,options={})
          MultiJson.dump(value.as_json(options), options) unless value.kind_of?(String)
        end

        def decode(value,options={})
          ::ActiveSupport::JSON.decode(value, options)
        end
      end

      module Xml
        module_function
        def encode(value,options={})
          value.to_xml(options)
        end

        def decode(value,options={})
          Hash.from_xml(value)
        end
      end
    end
  end
end
require 'uri'
require 'net/http'
require 'active_support/core_ext/module/delegation'
require 'cardiac'
require 'cardiac/resource'

module Cardiac

	class BaseReflection
		attr_reader :macro, :uri, :http_verb, :options
		alias http_verb?   http_verb
		alias http_method  http_verb
		alias http_method? http_verb?

		def initialize(resource_or_uri, http_verb=nil)
			@macro, @http_verb = self.class.build_macro, http_verb

			resource_or_uri.to_resource if resource_or_uri.respond_to?(:to_resource)
					
			case resource_or_uri
			when Cardiac::Resource
				@http_verb ||= resource_or_uri.method_value
				@uri = resource_or_uri.to_uri
				_options = resource_or_uri.send(:build_client_options, @http_verb)
			when URI
				@uri = resource_or_uri.dup
				_options = {}
			else
				@uri = resource_or_uri.to_uri if resource_or_uri.respond_to?(:to_uri)
				@http_verb ||= resource_or_uri.http_verb if resource_or_uri.respond_to?(:http_verb)
				@options ||= resource_or_uri.options if resource_or_uri.respond_to?(:options)
			end
			@options = _options.dup
			@options.symbolize_keys!
			@options[:method] = @http_verb
		end

		def to_uri
			@uri.dup
		end

		def to_url
			@uri.to_s
		end
		
		def to_reflection
		  self
		end

  private
  		
		def self.build_macro(name=self.name)
		  name.to_s.demodulize.sub(/Reflection$/,'').underscore.to_sym unless Symbol===name
		  name
		end
	end

	class ChainReflection
		attr_reader :macro, :base_reflection, :handler_chain, :block

		def initialize(macro, base, *handler_chain, &block)
			@macro, @base_reflection, @handler_chain, @block = macro, base, handler_chain, block
		end
	end
	
	class ResourceReflection < BaseReflection
		attr_reader :adapter_klass, :encoder_reflection, :decoder_reflections

		def initialize(resource, http_verb=nil)
			super resource, http_verb

			@decoder_reflections = resource.send(:build_decoders).map do |search,handler_chain|
				ChainReflection.new :decode, Representation::Reflection.new(search), *handler_chain
			end

			@encoder_reflection = ChainReflection.new :encode, *(resource.send(:build_encoder).tap do |search_and_chain|
			    search_and_chain[0] = Representation::Reflection.new(search_and_chain.first || :url_encoded)
			  end)
		end
	end
	
	class OperationReflection < ResourceReflection
		attr_reader :handler_klass
	end
end

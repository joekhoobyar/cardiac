module Cardiac
  module CodecMethods
    DEFAULT_DECODERS = [:url_encoded, :xml, :json].freeze
    
    # Representation decoder selection and customization.
    def decoders(search,*rest,&handler) self.decoders_values += check_decoders(rest.unshift(search),handler) ; self end
    def reset_decoders(*rest,&handler) decoders_values.replace check_decoders(rest,handler) ; self end

    # Representation encoder selection and customization.
    def encoder(search, &handler)
      self.encoder_search_value = search.presence or raise ArgumentError
      self.encoder_handler_value = handler
      self
    end

  protected
  
    # Delegates mime type lookups to Representation::Codecs.mimes_for
    def lookup_type(search,options={})
      ::Cardiac::Representation::Codecs.mimes_for(search,options)
    end

		def build_encoder(*previous)
			previous << encoder_handler_value if encoder_handler_value
			[encoder_search_value, previous]
		end
  
    # Builds a hash of decoder chains, keyed by symbol.
    #
    # In the decoder_values, zero or more symbols will precede each Proc in the chain,
    # specifying which decoder(s) it applies to.  If no symbols precede the Proc, then it will
    # be applicable to ALL decoders, even subsequently specified ones.  The order of
    # Proc objects in the chain are preserved, regardless of which decoders they are applicable to.
    # 
    def build_decoders(base_decoders=DEFAULT_DECODERS, base_handler=nil)
      all_chain, decoders = [], {}
      decoders_values.each do |value|
        case value
        when Proc
          decoders.each_value{|chain| chain << value }
          all_chain << value
        when Symbol
          decoders[value] = all_chain.dup
        end
      end
      base_decoders.each{|decoder| decoders[decoder] = all_chain.dup } if decoders.empty?
      decoders
    end
  
  private
  
    def check_decoders(decoders,handler=nil)
      raise ArgumentError unless decoders.all?{|k| Symbol===k }
      decoders << handler if handler
      decoders
    end
  end
end

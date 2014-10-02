require 'uri'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/indifferent_access'

module Cardiac
  module RequestMethods
    
    # The default accepts header type identifiers.
    DEFAULT_ACCEPTS = [:json, :xml]

    # HTTP method selection.
    def http_method(k) self.method_value = check_http_method(k) ; self end
      
    # Header selection.
    def headers(h,*rest) self.headers_values += check_headers(rest.unshift(h)) ; self end
    def reset_headers(*h) headers_values.replace check_headers(h) ; self end
    def header(key, value)
      raise ArgumentError unless String===key or Symbol===key
      raise ArgumentError if TrueClass===value
      self.headers_values << (FalseClass===value ? key : {key => value})
      self
    end
    def accepts(search,*rest) self.accepts_values += check_accepts(rest.unshift(search)) ; self end
    
    # Request option selection.
    def options(o,*rest) self.options_values += apply_request_options!(check_options(rest.unshift(o))) ; self end
    def reset_options(*o) options_values.replace apply_request_options!(check_options(o)) ; self end
    def option(key, value)
      raise ArgumentError unless String===key or Symbol===key
      raise ArgumentError if TrueClass===value
      self.options_values << (FalseClass===value ? key : {key => value})
      self
    end

    # Relative resource selection.
    def at(rel,options={})
      super(rel).options(options)
    end
    
    # Checking if the configured HTTP verb has requests that support a body.
    def request_has_body?
      net_http_request_klass::REQUEST_HAS_BODY
    end
    
    # Checking if the configured HTTP verb has responses that support a body.
    def response_has_body?
      net_http_request_klass::RESPONSE_HAS_BODY
    end
    
  protected
    
    def build_options(base_options={})
      options_values.inject base_options.with_indifferent_access do |o,v|
        case v
        when Hash          then o.deep_merge!(v)
        when String,Symbol then o.delete(v) ; o
        end
      end.symbolize_keys
    end
    
    def build_headers(base_headers={})
      base_headers = base_headers.with_indifferent_access
      base_headers[:content_type] = encoder_search_value if encoder_search_value.present?
      base_headers[:accepts] = build_accepts

      headers_values.inject base_headers.with_indifferent_access do |h,v|
        case v
        when Hash          then h.deep_merge!(v)
        when String,Symbol then h.delete(v) ; h
        end
      end.symbolize_keys
    end
    
    def build_accepts
      (accepts_values.presence || DEFAULT_ACCEPTS).dup
    end

    def build_http_method
      if method_value.nil?
        raise InvalidOperationError, 'no HTTP method specified'
      elsif ! net_http_request_klass
        raise InvalidOperationError, "unsupported HTTP method: #{method_value.to_s.upcase}"
      elsif ! allowed_http_methods.include?(method_value)
        raise InvalidOperationError, "disallowed HTTP method: #{method_value.to_s.upcase}"
      end
      method_value
    end

  private
  
    def check_http_method(http_method)
      if http_method.present?
        raise ArgumentError unless Symbol===http_method || String===http_method
        http_method.downcase.to_sym
      end
    end

    def check_options(options)
      raise ArgumentError unless options.all?{|o| Hash===o }
      options
    end

    def check_headers(headers)
      raise ArgumentError unless headers.all?{|h| Hash===h }
      headers
    end

    def check_accepts(searches)
      raise ArgumentError unless searches.all?{|a| Symbol===a || String===a }
      searches
    end
    
    def apply_request_option! key, value
      case key
      when :method, :http_method ; http_method(value)
      when :headers              ; headers(value)
      when :accepts              ; accepts(value)
      when :params               ; query(value)
      end
    end
    
    def apply_request_options! options
      options.map{|o| o.reject{|k,v| apply_request_option!(k,v) }.presence }.compact
    end
  
    def net_http_request_klass
      if method_value.present?
        verb = method_value.to_s.upcase
        if @request_klass && @request_klass::METHOD == verb
          @request_klass
        else
          klass = Net::HTTP.const_get(verb.capitalize) rescue nil
          @request_klass = klass if klass && klass::METHOD == verb
        end
      end
    end
  end
end
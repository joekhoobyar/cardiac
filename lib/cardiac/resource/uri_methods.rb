require 'uri'
require 'active_support/core_ext/hash/deep_merge'

module Cardiac
  module UriMethods

    # Scheme selection.
    def ssl(z)  self.https_value = z.nil? ? z : !!z; self end
    def http()  ssl(false) end
    def https() ssl(true)  end
    def scheme(word)
      case word
      when /^http$/i then http
      when /^https$/i then https
      when NilClass then ssl(nil)
      else raise ArgumentError
      end
    end

    # HTTP method selection.
    def http_method(k) self.method_value = k.to_s.downcase.to_sym ; self end

    # Userinfo selection.
    def user(s) self.user_value = s ; self end
    def password(s) self.password_value = s ; self end
    def userinfo(userinfo)
      if userinfo
        self.user_value, _password = userinfo.split(':',2)
        self.password_value ||= _password
      else
        self.user_value = self.password_value = nil
      end
      self
    end

    # Host and port selection.
    def host(s) self.host_value = s ; self end

    def port(n) self.port_value = n ; self end

    # Path selection.
    def path(s,*rest) self.path_values += check_paths(rest.unshift(s)) ; self end

    # Query parameter selection.
    def query(q,*rest) self.query_values += check_queries(rest.unshift(q)) ; self end
    def reset_query(*q) query_values.replace check_queries(q) ; self end

    # Relative resource selection.
    def at(rel)
      apply_uri_components! check_at(rel) if rel.present?
      self
    end

    # Convert this resource into a URI.
    def to_uri
      build_uri
    end
    
    # Convert this resource into an URL string.
    def to_url
      to_uri.to_s
    end

    # Convert this resource into a relative URI.
    def to_relative_uri
      build_uri.route_from base_value
    end
    
    # Convert this resource into a relative URL string
    def to_relative_url
      to_relative_uri.to_s
    end

    protected

    # Derives the userinfo from the user_value and password_value.
    def build_userinfo
      @password_value ? "#{@user_value}:#{@password_value}" : @user_value if @user_value
    end
    
    # Derives the scheme from the base_value and https_value.
    def build_scheme
      case @https_value
      when FalseClass then 'http'
      when NilClass then base_value.scheme || 'http'
      else 'https'
      end
    end
    
    # Derives the path from the base_value and paths_value.
    def build_path
      @path_values.inject(base_value){|uri,path| uri.merge URI::Generic.build(path: path) }.path
    end
    
    # Needed by Subresource
    def build_query_values
      @query_values.select(&:present?)
    end
    
    # Derives the query from the built-up query_values.
    def build_query
      case query = build_query_values.inject{|q,v| query_coder.decode(q).deep_merge(query_coder.decode(v)) }
      when Hash
        query_coder.encode(query)
      when String, NilClass
        query
      else
        raise InvalidRepresentationError, 'expected Hash, String, or NilClass but got: '+query.class.name
      end
    end

    # Derives a URI from the built-up values in this resource.    
    def build_uri
      # Validate the scheme.
      scheme = build_scheme.upcase
      raise UnresolvableResourceError, 'scheme must be http or https' if scheme!='HTTP' && scheme!='HTTPS'
      
      # Build and normalize the URI.
      URI.const_get(scheme).
        build2(host: build_host, port: build_port(scheme), userinfo: build_userinfo, path: build_path, query: build_query).
        normalize
    end
    
    # Derives a host from the built-up values in this resource, requiring it to be present.
    def build_host
      host = @host_value || base_value.host
      raise UnresolvableResourceError, 'no HTTP host specified' if host.blank?
      host
    end
    
    # Derives a port from the built-up values in this resource, but omits default ports.
    def build_port(scheme=nil)
      non_default_port(scheme, @port_value || non_default_port(base_value.scheme, base_value.port))
    end

  private

    # Returns nil if the given port is the default for the scheme, otherwise returns the port itself.
    def non_default_port(scheme,port)
      case scheme
      when /^http$/i  then port==80  ? nil : port
      when /^https$/i then port==443 ? nil : port
      else port
      end
    end
    
    def query_coder
      ::Cardiac::Representation::Codecs::UrlEncoded
    end
    
    def apply_uri_components! other
      other, base = to_uri.coerce(other)
      base.component.each do |part|
        next if part == :fragment
        value = other.send(part)
        send(part, value) if base.merge!(URI::Generic.build(part => value))
      end
      base
    end

    def check_at(rel)
      raise ArgumentError unless String===rel or URI===rel
      rel
    end

    def check_paths(paths)
      raise ArgumentError unless paths.all?{|s| String===s }
      paths
    end

    def check_queries(queries)
      raise ArgumentError unless queries.all?{|q| String===q || Hash===q }
      queries
    end
  end
end
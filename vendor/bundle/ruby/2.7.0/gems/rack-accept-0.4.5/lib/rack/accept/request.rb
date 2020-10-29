require 'rack/request'

module Rack::Accept
  # A container class for convenience methods when Rack::Accept is used on the
  # request level as Rack middleware. Instances of this class also manage a
  # lightweight cache of various header instances to speed up execution.
  class Request < Rack::Request
    attr_reader :env

    def initialize(env)
      @env = env
    end

    # Provides access to the Rack::Accept::MediaType instance for this request.
    def media_type
      @media_type ||= MediaType.new(env['HTTP_ACCEPT'])
    end

    # Provides access to the Rack::Accept::Charset instance for this request.
    def charset
      @charset ||= Charset.new(env['HTTP_ACCEPT_CHARSET'])
    end

    # Provides access to the Rack::Accept::Encoding instance for this request.
    def encoding
      @encoding ||= Encoding.new(env['HTTP_ACCEPT_ENCODING'])
    end

    # Provides access to the Rack::Accept::Language instance for this request.
    def language
      @language ||= Language.new(env['HTTP_ACCEPT_LANGUAGE'])
    end

    # Returns true if the +Accept+ request header indicates the given media
    # type is acceptable, false otherwise.
    def media_type?(value)
      media_type.accept?(value)
    end

    # Returns true if the +Accept-Charset+ request header indicates the given
    # character set is acceptable, false otherwise.
    def charset?(value)
      charset.accept?(value)
    end

    # Returns true if the +Accept-Encoding+ request header indicates the given
    # encoding is acceptable, false otherwise.
    def encoding?(value)
      encoding.accept?(value)
    end

    # Returns true if the +Accept-Language+ request header indicates the given
    # language is acceptable, false otherwise.
    def language?(value)
      language.accept?(value)
    end

    # Determines the best media type to use in a response from the given media
    # types, if any is acceptable. For more information on how this value is
    # determined, see the documentation for
    # Rack::Accept::Header::PublicInstanceMethods#sort.
    def best_media_type(values)
      media_type.best_of(values)
    end

    # Determines the best character set to use in a response from the given
    # character sets, if any is acceptable. For more information on how this
    # value is determined, see the documentation for
    # Rack::Accept::Header::PublicInstanceMethods#sort.
    def best_charset(values)
      charset.best_of(values)
    end

    # Determines the best encoding to use in a response from the given
    # encodings, if any is acceptable. For more information on how this value
    # is determined, see the documentation for
    # Rack::Accept::Header::PublicInstanceMethods#sort.
    def best_encoding(values)
      encoding.best_of(values)
    end

    # Determines the best language to use in a response from the given
    # languages, if any is acceptable. For more information on how this value
    # is determined, see the documentation for
    # Rack::Accept::Header::PublicInstanceMethods#sort.
    def best_language(values)
      language.best_of(values)
    end
  end
end

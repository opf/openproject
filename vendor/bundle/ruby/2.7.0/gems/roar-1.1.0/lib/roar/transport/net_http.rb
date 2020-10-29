require 'roar/transport/net_http/request'

module Roar
  # Implements the (HTTP) transport interface with Net::HTTP.
  module Transport
    # Low-level interface for HTTP. The #get_uri and friends accept an options and an optional block, invoke
    # the HTTP request and return the request object.
    #
    # The following options are available:
    class NetHTTP

      def get_uri(*options, &block)
        call(Net::HTTP::Get, *options, &block)
      end

      def post_uri(*options, &block)
        call(Net::HTTP::Post, *options, &block)
      end

      def put_uri(*options, &block)
        call(Net::HTTP::Put, *options, &block)
      end

      def delete_uri(*options, &block)
        call(Net::HTTP::Delete, *options, &block)
      end

      def patch_uri(*options, &block)
        call(Net::HTTP::Patch, *options, &block)
      end

    private
      def call(what, options, &block)
        # TODO: generically handle return codes.
        Request.new(options).call(what, &block)
      end
    end

    # Wraps the original response from NetHttp and provides it via #response.
    class Error < RuntimeError # TODO: raise this from Faraday, too.
      def initialize(response)
        @response = response
        super("Roar error: #{response}")
      end

      attr_reader :response
    end
  end
end

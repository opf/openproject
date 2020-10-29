gem 'faraday'
require 'faraday'

module Roar
  module Transport
    # Advanced implementation of the HTTP verbs with the Faraday HTTP library
    # (which can, in turn, use adapters based on Net::HTTP or libcurl)
    #
    # Depending on how the Faraday middleware stack is configured, this
    # Transport can support features such as HTTP error code handling,
    # redirects, etc.
    #
    # @see http://rubydoc.info/gems/faraday/file/README.md Faraday README
    class Faraday

      def get_uri(options)
        build_connection(options[:uri], options[:as]).get
      end

      def post_uri(options)
        build_connection(options[:uri], options[:as]).post(nil, options[:body])
      end

      def put_uri(options)
        build_connection(options[:uri], options[:as]).put(nil, options[:body])
      end

      def patch_uri(options)
        build_connection(options[:uri], options[:as]).patch(nil, options[:body])
      end

      def delete_uri(options)
        build_connection(options[:uri], options[:as]).delete
      end

      private

      def build_connection(uri, as)
        ::Faraday::Connection.new(
          :url => uri,
          :headers => { :accept => as, :content_type => as }
        ) do |builder|
          builder.use ::Faraday::Response::RaiseError
          builder.adapter ::Faraday.default_adapter
        end
      end
    end
  end
end

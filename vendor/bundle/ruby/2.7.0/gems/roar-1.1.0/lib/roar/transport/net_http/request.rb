require "net/http"
require "openssl"

module Roar
  module Transport
    class NetHTTP
      class Request # TODO: implement me.
        def initialize(options)
          @uri     = parse_uri(options[:uri]) # TODO: add :uri.
          @as      = options[:as]
          @body    = options[:body]
          @options = options

          @http = Net::HTTP.new(uri.host, uri.port)
          unless options[:pem_file].nil?
            pem = File.read(options[:pem_file])
            @http.use_ssl = true
            @http.cert = OpenSSL::X509::Certificate.new(pem)
            @http.key = OpenSSL::PKey::RSA.new(pem)
            @http.verify_mode = options[:ssl_verify_mode].nil? ? OpenSSL::SSL::VERIFY_PEER : options[:ssl_verify_mode]
          end
        end

        def call(what)
          @req = what.new(uri.request_uri)

          # if options[:ssl]
          #   uri.port = Net::HTTP.https_default_port()
          # end
          https!
          basic_auth!

          req.content_type = as
          req["accept"]    = as # TODO: test me. # DISCUSS: if Accept is not set, rails treats this request as as "text/html".
          req.body         = body if body

          yield req if block_given?

          http.request(req).tap do |res|
            handle_error!(res)
          end
        end

        def get
          call(Net::HTTP::Get)
        end

        private
        attr_reader :uri, :as, :body, :options, :req, :http

        def parse_uri(url)
          uri = URI(url)
          raise "Incorrect URL `#{url}`. Maybe you forgot http://?" if uri.instance_of?(URI::Generic)
          uri
        end

        def https!
          return unless uri.scheme == 'https'

          @http.use_ssl     = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        def basic_auth!
          return unless options[:basic_auth]

          @req.basic_auth(*options[:basic_auth])
        end

        def handle_error!(res)
          status = res.code.to_i
          raise Error.new(res) unless status >= 200 and status < 300
        end
      end
    end
  end
end

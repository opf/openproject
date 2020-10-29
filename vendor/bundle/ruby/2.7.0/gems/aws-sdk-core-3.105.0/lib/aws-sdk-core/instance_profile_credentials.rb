# frozen_string_literal: true

require 'time'
require 'net/http'

module Aws
  class InstanceProfileCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @api private
    class Non200Response < RuntimeError; end

    # @api private
    class TokenRetrivalError < RuntimeError; end

    # @api private
    class TokenExpiredError < RuntimeError; end

    # These are the errors we trap when attempting to talk to the
    # instance metadata service.  Any of these imply the service
    # is not present, no responding or some other non-recoverable
    # error.
    # @api private
    NETWORK_ERRORS = [
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ENETUNREACH,
      SocketError,
      Timeout::Error,
      Non200Response
    ].freeze

    # Path base for GET request for profile and credentials
    # @api private
    METADATA_PATH_BASE = '/latest/meta-data/iam/security-credentials/'.freeze

    # Path for PUT request for token
    # @api private
    METADATA_TOKEN_PATH = '/latest/api/token'.freeze

    # @param [Hash] options
    # @option options [Integer] :retries (1) Number of times to retry
    #   when retrieving credentials.
    # @option options [String] :ip_address ('169.254.169.254')
    # @option options [Integer] :port (80)
    # @option options [Float] :http_open_timeout (1)
    # @option options [Float] :http_read_timeout (1)
    # @option options [Numeric, Proc] :delay By default, failures are retried
    #   with exponential back-off, i.e. `sleep(1.2 ** num_failures)`. You can
    #   pass a number of seconds to sleep between failed attempts, or
    #   a Proc that accepts the number of failures.
    # @option options [IO] :http_debug_output (nil) HTTP wire
    #   traces are sent to this object.  You can specify something
    #   like $stdout.
    # @option options [Integer] :token_ttl Time-to-Live in seconds for EC2
    #   Metadata Token used for fetching Metadata Profile Credentials, defaults
    #   to 21600 seconds
    def initialize(options = {})
      @retries = options[:retries] || 1
      @ip_address = options[:ip_address] || '169.254.169.254'
      @port = options[:port] || 80
      @http_open_timeout = options[:http_open_timeout] || 1
      @http_read_timeout = options[:http_read_timeout] || 1
      @http_debug_output = options[:http_debug_output]
      @backoff = backoff(options[:backoff])
      @token_ttl = options[:token_ttl] || 21_600
      @token = nil
      super
    end

    # @return [Integer] Number of times to retry when retrieving credentials
    #   from the instance metadata service. Defaults to 0 when resolving from
    #   the default credential chain ({Aws::CredentialProviderChain}).
    attr_reader :retries

    private

    def backoff(backoff)
      case backoff
      when Proc then backoff
      when Numeric then ->(_) { sleep(backoff) }
      else ->(num_failures) { Kernel.sleep(1.2**num_failures) }
      end
    end

    def refresh
      # Retry loading credentials up to 3 times is the instance metadata
      # service is responding but is returning invalid JSON documents
      # in response to the GET profile credentials call.
      begin
        retry_errors([Aws::Json::ParseError, StandardError], max_retries: 3) do
          c = Aws::Json.load(get_credentials.to_s)
          @credentials = Credentials.new(
            c['AccessKeyId'],
            c['SecretAccessKey'],
            c['Token']
          )
          @expiration = c['Expiration'] ? Time.iso8601(c['Expiration']) : nil
        end
      rescue Aws::Json::ParseError
        raise Aws::Errors::MetadataParserError
      end
    end

    def get_credentials
      # Retry loading credentials a configurable number of times if
      # the instance metadata service is not responding.
      if _metadata_disabled?
        '{}'
      else
        begin
          retry_errors(NETWORK_ERRORS, max_retries: @retries) do
            open_connection do |conn|
              # attempt to fetch token to start secure flow first
              # and rescue to failover
              begin
                retry_errors(NETWORK_ERRORS, max_retries: @retries) do
                  unless token_set?
                    token_value, ttl = http_put(
                      conn, METADATA_TOKEN_PATH, @token_ttl
                    )
                    @token = Token.new(token_value, ttl) if token_value && ttl
                  end
                end
              rescue *NETWORK_ERRORS
                # token attempt failed, reset token
                # fallback to non-token mode
                @token = nil
              end

              token = @token.value if token_set?
              metadata = http_get(conn, METADATA_PATH_BASE, token)
              profile_name = metadata.lines.first.strip
              http_get(conn, METADATA_PATH_BASE + profile_name, token)
            end
          end
        rescue
          '{}'
        end
      end
    end

    def token_set?
      @token && !@token.expired?
    end

    def _metadata_disabled?
      ENV.fetch('AWS_EC2_METADATA_DISABLED', 'false').downcase == 'true'
    end

    def open_connection
      http = Net::HTTP.new(@ip_address, @port, nil)
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout
      http.set_debug_output(@http_debug_output) if @http_debug_output
      http.start
      yield(http).tap { http.finish }
    end

    # GET request fetch profile and credentials
    def http_get(connection, path, token = nil)
      headers = { 'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}" }
      headers['x-aws-ec2-metadata-token'] = token if token
      response = connection.request(Net::HTTP::Get.new(path, headers))
      raise Non200Response unless response.code.to_i == 200

      response.body
    end

    # PUT request fetch token with ttl
    def http_put(connection, path, ttl)
      headers = {
        'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}",
        'x-aws-ec2-metadata-token-ttl-seconds' => ttl.to_s
      }
      response = connection.request(Net::HTTP::Put.new(path, headers))
      case response.code.to_i
      when 200
        [
          response.body,
          response.header['x-aws-ec2-metadata-token-ttl-seconds'].to_i
        ]
      when 400
        raise TokenRetrivalError
      when 401
        raise TokenExpiredError
      else
        raise Non200Response
      end
    end

    def retry_errors(error_classes, options = {}, &_block)
      max_retries = options[:max_retries]
      retries = 0
      begin
        yield
      rescue *error_classes
        raise unless retries < max_retries

        @backoff.call(retries)
        retries += 1
        retry
      end
    end

    # @api private
    # Token used to fetch IMDS profile and credentials
    class Token
      def initialize(value, ttl)
        @ttl = ttl
        @value = value
        @created_time = Time.now
      end

      # [String] token value
      attr_reader :value

      def expired?
        Time.now - @created_time > @ttl
      end
    end
  end
end

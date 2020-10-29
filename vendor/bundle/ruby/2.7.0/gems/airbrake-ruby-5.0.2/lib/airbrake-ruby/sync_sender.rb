module Airbrake
  # Responsible for sending data to Airbrake synchronously via PUT or POST
  # methods. Supports proxies.
  #
  # @see AsyncSender
  # @api private
  # @since v1.0.0
  class SyncSender
    # @return [String] body for HTTP requests
    CONTENT_TYPE = 'application/json'.freeze

    include Loggable

    # @param [Symbol] method HTTP method to use to send payload
    def initialize(method = :post)
      @config = Airbrake::Config.instance
      @method = method
      @rate_limit_reset = Time.now
    end

    # Sends a POST or PUT request to the given +endpoint+ with the +data+ payload.
    #
    # @param [#to_json] data
    # @param [URI::HTTPS] endpoint
    # @return [Hash{String=>String}] the parsed HTTP response
    def send(data, promise, endpoint = @config.error_endpoint)
      return promise if rate_limited_ip?(promise)

      response = nil
      req = build_request(endpoint, data)

      return promise if missing_body?(req, promise)

      https = build_https(endpoint)

      begin
        response = https.request(req)
      rescue StandardError => ex
        reason = "#{LOG_LABEL} HTTP error: #{ex}"
        logger.error(reason)
        return promise.reject(reason)
      end

      parsed_resp = Response.parse(response)
      if parsed_resp.key?('rate_limit_reset')
        @rate_limit_reset = parsed_resp['rate_limit_reset']
      end

      return promise.reject(parsed_resp['error']) if parsed_resp.key?('error')

      promise.resolve(parsed_resp)
    end

    private

    def build_https(uri)
      Net::HTTP.new(uri.host, uri.port, *proxy_params).tap do |https|
        https.use_ssl = uri.is_a?(URI::HTTPS)
        if @config.timeout
          https.open_timeout = @config.timeout
          https.read_timeout = @config.timeout
        end
      end
    end

    def build_request(uri, data)
      req =
        if @method == :put
          Net::HTTP::Put.new(uri.request_uri)
        else
          Net::HTTP::Post.new(uri.request_uri)
        end

      build_request_body(req, data)
    end

    def build_request_body(req, data)
      req.body = data.to_json

      req['Authorization'] = "Bearer #{@config.project_key}"
      req['Content-Type'] = CONTENT_TYPE
      req['User-Agent'] =
        "#{Airbrake::NOTIFIER_INFO[:name]}/#{Airbrake::AIRBRAKE_RUBY_VERSION}" \
        " Ruby/#{RUBY_VERSION}"

      req
    end

    def proxy_params
      return unless @config.proxy.key?(:host)

      [@config.proxy[:host], @config.proxy[:port], @config.proxy[:user],
       @config.proxy[:password]]
    end

    def rate_limited_ip?(promise)
      rate_limited = Time.now < @rate_limit_reset
      promise.reject("#{LOG_LABEL} IP is rate limited") if rate_limited
      rate_limited
    end

    def missing_body?(req, promise)
      missing = req.body.nil?

      if missing
        reason = "#{LOG_LABEL} data was not sent because of missing body"
        logger.error(reason)
        promise.reject(reason)
      end

      missing
    end
  end
end

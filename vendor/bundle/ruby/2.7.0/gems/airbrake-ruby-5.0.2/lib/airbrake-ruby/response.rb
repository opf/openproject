module Airbrake
  # Parses responses coming from the Airbrake API. Handles HTTP errors by
  # logging them.
  #
  # @api private
  # @since v1.0.0
  module Response
    # @return [Integer] the limit of the response body
    TRUNCATE_LIMIT = 100

    # @return [Integer] HTTP code returned when an IP sends over 10k/min notices
    TOO_MANY_REQUESTS = 429

    class << self
      include Loggable
    end

    # Parses HTTP responses from the Airbrake API.
    #
    # @param [Net::HTTPResponse] response
    # @return [Hash{String=>String}] parsed response
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def self.parse(response)
      code = response.code.to_i
      body = response.body

      begin
        case code
        when 200, 204
          logger.debug("#{LOG_LABEL} #{name} (#{code}): #{body}")
          { response.msg => response.body }
        when 201
          parsed_body = JSON.parse(body)
          logger.debug("#{LOG_LABEL} #{name} (#{code}): #{parsed_body}")
          parsed_body
        when 400, 401, 403, 420
          parsed_body = JSON.parse(body)
          logger.error("#{LOG_LABEL} #{parsed_body['message']}")
          parsed_body
        when TOO_MANY_REQUESTS
          parsed_body = JSON.parse(body)
          msg = "#{LOG_LABEL} #{parsed_body['message']}"
          logger.error(msg)
          { 'error' => msg, 'rate_limit_reset' => rate_limit_reset(response) }
        else
          body_msg = truncated_body(body)
          logger.error("#{LOG_LABEL} unexpected code (#{code}). Body: #{body_msg}")
          { 'error' => body_msg }
        end
      rescue StandardError => ex
        body_msg = truncated_body(body)
        logger.error("#{LOG_LABEL} error while parsing body (#{ex}). Body: #{body_msg}")
        { 'error' => ex.inspect }
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def self.truncated_body(body)
      if body.nil?
        '[EMPTY_BODY]'.freeze
      elsif body.length > TRUNCATE_LIMIT
        body[0..TRUNCATE_LIMIT] << '...'
      else
        body
      end
    end
    private_class_method :truncated_body

    def self.rate_limit_reset(response)
      Time.now + response['X-RateLimit-Delay'].to_i
    end
    private_class_method :rate_limit_reset
  end
end

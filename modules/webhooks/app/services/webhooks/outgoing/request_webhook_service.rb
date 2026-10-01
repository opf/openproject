module Webhooks
  module Outgoing
    class RequestWebhookService
      include ::OpenProjectErrorHelper

      attr_reader :current_user, :event_name, :webhook

      def initialize(webhook, event_name:, current_user:)
        @current_user = current_user
        @webhook = webhook
        @event_name = event_name
      end

      def call!(body:, headers:)
        begin
          response = OpenProject::SsrfProtection.post(
            webhook.url,
            headers:,
            body:
          )
        rescue SsrfFilter::PrivateIPAddress => e
          message = "#{e.message} - If this is intentional, add the IP to the allowlist via " \
                    "the OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST environment variable."
          op_handle_error(message, reference: :webhook_job)
          exception = e.exception(message)
        rescue StandardError => e
          op_handle_error(e.message, reference: :webhook_job)
          exception = e
        end

        log!(body:, headers:, response:, exception:)

        # We want to re-raise timeout exceptions so that good_job retries the request because
        # we assume that a timeout could have been a temporary issue.
        raise exception if exception.is_a?(Net::OpenTimeout) || exception.is_a?(Net::ReadTimeout)
      end

      def log!(body:, headers:, response:, exception:)
        log = ::Webhooks::Log.new(
          webhook:,
          event_name:,
          url: webhook.url,
          request_headers: headers,
          request_body: body,
          **response_attributes(response:, exception:)
        )

        unless log.save
          OpenProject.logger.error("Failed to save webhook log: #{log.errors.full_messages.join('. ')}")
        end
      end

      def response_attributes(response:, exception:)
        {
          response_code: response&.code&.to_i || -1,
          response_headers: response_headers(response),
          response_body: response&.body || exception&.message
        }
      end

      def response_headers(response)
        response
          &.to_hash
          &.transform_keys { |k| k.underscore.to_sym }
          &.transform_values(&:first)
      end
    end
  end
end

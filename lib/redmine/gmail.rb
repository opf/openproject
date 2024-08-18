require "google/apis/gmail_v1"
require "googleauth"

module Redmine
  module Gmail
    class << self
      def check(gmail_options = {}, options = {})
        credentials = gmail_options[:credentials] || ""
        username = gmail_options[:user_id] || ""
        query = gmail_options[:query] || ""

        gmail = Google::Apis::GmailV1::GmailService.new
        gmail.authorization = authenticate(credentials, username)

        gmail.list_user_messages("me", q: query, max_results: gmail_options[:max_emails]).messages.each do |message|
          receive(message.id, gmail, gmail_options, options)
        end
      end

      def authenticate(credentials, user_id)
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(credentials),
          scope: "https://www.googleapis.com/auth/gmail.modify"
        )
        credentials.update!(sub: user_id)

        credentials
      end

      def receive(message_id, gmail, gmail_options, options)
        email = gmail.get_user_message("me", message_id, format: "raw")
        msg = email.raw

        raise "Messages was not successfully handled." unless MailHandler.receive(msg, options)

        message_received(message_id, gmail, gmail_options)
      rescue StandardError => e
        Rails.logger.error { "Message #{message_id} resulted in error #{e} #{e.message}" }
        message_error(message_id, gmail, gmail_options)
      end

      def message_received(message_id, gmail, _gmail_options)
        log_debug { "Message #{message_id} successfully received" }

        modify_request = Google::Apis::GmailV1::ModifyThreadRequest.new(remove_label_ids: ["UNREAD"])
        gmail.modify_message("me", message_id, modify_request)
      end

      def message_error(message_id, gmail, gmail_options)
        log_debug { "Message #{message_id} can not be processed" }

        if gmail_options[:read_on_failure]
          modify_request = Google::Apis::GmailV1::ModifyThreadRequest.new(remove_label_ids: ["UNREAD"])
          gmail.modify_message("me", message_id, modify_request)
        end
      end

      def log_debug(&)
        logger.debug(&)
      end

      def logger
        Rails.logger
      end
    end
  end
end

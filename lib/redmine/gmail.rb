# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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

        raise "Messages was not successfully handled." unless IncomingEmails::MailHandler.receive(msg, options)

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

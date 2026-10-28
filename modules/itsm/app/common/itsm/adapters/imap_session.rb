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

require "net/imap"

module ITSM
  module Adapters
    class ImapSession
      include Concerns::ImapRequest

      OPEN_TIMEOUT = 10
      SESSION_TIMEOUT = 5.minutes
      FOLDER = "INBOX"

      class GreetingTimeout < StandardError; end

      def self.open(mail_server:, auth_strategy:)
        session = new(mail_server:, auth_strategy:)
        deadline = Concurrent::ScheduledTask.execute(SESSION_TIMEOUT) { session.time_out }
        session.connect.bind { yield session }
      ensure
        deadline&.cancel
        session&.close
      end

      def initialize(mail_server:, auth_strategy:)
        @mail_server = mail_server
        @auth_strategy = auth_strategy
      end

      def connect
        safe_address
          .bind { imap_request { open_connection } }
          # The strategy returns its own Result, which imap_request wraps once more.
          .bind { imap_request { auth_strategy.call(imap) }.flatten }
          .bind { imap_request { imap.select(FOLDER) } }
          .fmap { self }
      end

      def request(source:)
        imap_request(source:) { yield imap }
      end

      def close
        return if imap.nil? || imap.disconnected?

        logout = imap_request { imap.logout }
        imap_request { imap.disconnect }
        Rails.logger.warn { "IMAP logout failed (#{logout.failure.code})" } if logout.failure?
      end

      # Net::IMAP has no command timeout yet: https://github.com/ruby/net-imap/issues/278
      # Disconnecting from another thread makes the waiting command fail with an IOError.
      def time_out
        @timed_out = true
        imap&.disconnect
      end

      private

      attr_reader :mail_server, :auth_strategy, :imap, :timed_out

      def instance_variables_to_inspect = %i[@mail_server]

      def imap_request(source: self.class)
        super.alt_map { timed_out ? it.with(code: :timeout) : it }
      rescue GreetingTimeout
        failure(code: :timeout, source:)
      end

      def safe_address
        addresses = OpenProject::SsrfProtection.resolver.call(mail_server.host)

        return failure(code: :unreachable) if addresses.empty?
        return failure(code: :address_not_allowed) unless addresses.all? { OpenProject::SsrfProtection.safe_ip?(it) }

        Success(addresses)
      end

      # Net::IMAP.new waits for the server greeting without a time limit, and the session timeout
      # cannot disconnect a connection that is still being opened.
      def open_connection
        @imap = Timeout.timeout(OPEN_TIMEOUT, GreetingTimeout) do
          Net::IMAP.new(mail_server.host, port: mail_server.port, ssl: mail_server.tls?, open_timeout: OPEN_TIMEOUT)
        end
        imap.starttls if mail_server.starttls?
      end
    end
  end
end

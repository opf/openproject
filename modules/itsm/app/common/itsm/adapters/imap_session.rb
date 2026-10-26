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
      FOLDER = "INBOX"

      def self.open(connection:, auth_strategy:)
        session = new(connection:, auth_strategy:)
        session.connect.bind { yield session }
      ensure
        session&.close
      end

      def initialize(connection:, auth_strategy:)
        @connection = connection
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
        Rails.logger.warn { "IMAP logout failed: #{logout.failure.payload}" } if logout.failure?
      end

      private

      attr_reader :connection, :auth_strategy, :imap

      def instance_variables_to_inspect = %i[@connection]

      def safe_address
        addresses = OpenProject::SsrfProtection.resolver.call(connection.host)

        return failure(code: :unreachable) if addresses.empty?
        return failure(code: :address_not_allowed) unless addresses.all? { OpenProject::SsrfProtection.safe_ip?(it) }

        Success(addresses)
      end

      def open_connection
        @imap = Net::IMAP.new(connection.host, port: connection.port, ssl: connection.tls?, open_timeout: OPEN_TIMEOUT)
        imap.starttls if connection.starttls?
      end
    end
  end
end

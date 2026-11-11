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
    class ImapConnection < Net::IMAP
      def initialize(host, addresses:, **)
        @addresses = addresses
        super(host, **)
      end

      private

      # Connects to the addresses that passed the SSRF check instead of resolving the host again,
      # while TLS still uses the host for SNI and certificate verification.
      # Net::IMAP waits for the server greeting without a time limit, so the socket has one until it arrives.
      def tcp_socket(_host, port)
        @addresses.each_with_index do |address, index|
          return super(address, port).tap { it.timeout = open_timeout }
        rescue SystemCallError, Net::OpenTimeout => e
          raise if index == @addresses.size - 1

          Rails.logger.warn { "Connecting to #{address} failed (#{e.class.name}), trying the next address" }
        end
      end

      def get_server_greeting
        super
      ensure
        @sock.to_io.timeout = nil
      end
    end
  end
end

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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "net/imap"

module Redmine
  module IMAP
    class << self
      def check(imap_options = {}, options = {})
        folder = imap_options[:folder].presence || "INBOX"
        imap = connect_imap(imap_options)

        imap.select(folder)
        imap.search(["NOT", "SEEN"]).each do |message_id|
          receive(message_id, imap, imap_options, options)
        end

        imap.expunge
      end

      private

      def connect_imap(imap_options)
        host = imap_options[:host] || "127.0.0.1"
        port = imap_options[:port] || "143"
        verify_mode = imap_options[:ssl_verification] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        ssl_params =
          if imap_options[:ssl]
            { verify_mode: }
          else
            false
          end

        imap = Net::IMAP.new(host, port:, ssl: ssl_params)

        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?

        imap
      end

      def receive(message_id, imap, imap_options, options)
        msg = imap.fetch(message_id, "RFC822")[0].attr["RFC822"]
        raise "Message was not successfully handled." unless MailHandler.receive(msg, options)

        message_received(message_id, imap, imap_options)
      rescue StandardError => e
        Rails.logger.error { "Message #{message_id} resulted in error #{e} #{e.message}" }
        message_error(message_id, imap, imap_options)
      end

      def message_received(message_id, imap, imap_options)
        log_debug { "Message #{message_id} successfully received" }

        if imap_options[:move_on_success]
          imap.copy(message_id, imap_options[:move_on_success])
        end

        imap.store(message_id, "+FLAGS", %i[Seen Deleted])
      end

      def message_error(message_id, imap, imap_options)
        log_debug { "Message #{message_id} can not be processed" }

        imap.store(message_id, "+FLAGS", [:Seen])

        if imap_options[:move_on_failure]
          imap.copy(message_id, imap_options[:move_on_failure])
          imap.store(message_id, "+FLAGS", [:Deleted])
        end
      end

      def log_debug(&)
        logger.debug(yield) if logger && logger.debug?
      end

      def logger
        Rails.logger
      end
    end
  end
end

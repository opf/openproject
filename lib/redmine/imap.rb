#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'net/imap'

module Redmine
  module IMAP
    class << self
      def check(imap_options = {}, options = {})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        folder = imap_options[:folder] || 'INBOX'

        imap = Net::IMAP.new(host, port, ssl)
        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        imap.select(folder)
        imap.search(['NOT', 'SEEN']).each do |message_id|
          msg = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
          logger.debug "Receiving message #{message_id}" if logger && logger.debug?
          if MailHandler.receive(msg, options)
            logger.debug "Message #{message_id} successfully received" if logger && logger.debug?
            if imap_options[:move_on_success]
              imap.copy(message_id, imap_options[:move_on_success])
            end
            imap.store(message_id, '+FLAGS', [:Seen, :Deleted])
          else
            logger.debug "Message #{message_id} can not be processed" if logger && logger.debug?
            imap.store(message_id, '+FLAGS', [:Seen])
            if imap_options[:move_on_failure]
              imap.copy(message_id, imap_options[:move_on_failure])
              imap.store(message_id, '+FLAGS', [:Deleted])
            end
          end
        end
        imap.expunge
      end

      private

      def logger
        Rails.logger
      end
    end
  end
end

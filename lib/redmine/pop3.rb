#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'net/pop'

module Redmine
  module POP3
    class << self
      def check(pop_options={}, options={})
        host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')
        delete_unprocessed = (pop_options[:delete_unprocessed].to_s == '1')

        pop = Net::POP3.APOP(apop).new(host,port)
        logger.debug "Connecting to #{host}..." if logger && logger.debug?
        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          if pop_session.mails.empty?
            logger.debug "No email to process" if logger && logger.debug?
          else
            logger.debug "#{pop_session.mails.size} email(s) to process..." if logger && logger.debug?
            pop_session.each_mail do |msg|
              message = msg.pop
              message_id = (message =~ /^Message-ID: (.*)/ ? $1 : '').strip
              if MailHandler.receive(message, options)
                msg.delete
                logger.debug "--> Message #{message_id} processed and deleted from the server" if logger && logger.debug?
              else
                if delete_unprocessed
                  msg.delete
                  logger.debug "--> Message #{message_id} NOT processed and deleted from the server" if logger && logger.debug?
                else
                  logger.debug "--> Message #{message_id} NOT processed and left on the server" if logger && logger.debug?
                end
              end
            end
          end
        end
      end

      private

      def logger
        RAILS_DEFAULT_LOGGER
      end
    end
  end
end

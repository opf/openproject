require 'net/imap'

module Redmine
  module IMAP
    class << self
      def check(imap_options={}, options={})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        folder = imap_options[:folder] || 'INBOX'
        
        imap = Net::IMAP.new(host, port, ssl)        
        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        imap.select(folder)
        imap.search(['NOT', 'SEEN']).each do |message_id|
          msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
          logger.debug "Receiving message #{message_id}" if logger && logger.debug?
          if MailHandler.receive(msg, options)
            logger.debug "Message #{message_id} successfully received" if logger && logger.debug?
            if imap_options[:move_on_success]
              imap.copy(message_id, imap_options[:move_on_success])
            end
            imap.store(message_id, "+FLAGS", [:Seen, :Deleted])
          else
            logger.debug "Message #{message_id} can not be processed" if logger && logger.debug?
            imap.store(message_id, "+FLAGS", [:Seen])
            if imap_options[:move_on_failure]
              imap.copy(message_id, imap_options[:move_on_failure])
              imap.store(message_id, "+FLAGS", [:Deleted])
            end
          end
        end
        imap.expunge
      end
      
      private
      
      def logger
        RAILS_DEFAULT_LOGGER
      end
    end
  end
end

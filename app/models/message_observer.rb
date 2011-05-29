class MessageObserver < ActiveRecord::Observer
  def after_save(message)
    if message.last_journal.version == 1
      # Only deliver mails for the first journal
      Mailer.deliver_message_posted(message) if Setting.notified_events.include?('message_posted')
    end
  end
end

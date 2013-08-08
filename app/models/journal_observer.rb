#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class JournalObserver < ActiveRecord::Observer
  attr_accessor :send_notification

  def after_create(journal)
    if journal.journaled_type == "WorkPackageJournal" and !journal.initial? and send_notification
      after_create_issue_journal(journal)
    end
    clear_notification
  end

  def after_create_issue_journal(journal)
    if Setting.notified_events.include?('issue_updated') ||
        (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
        (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
        (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
      issue = journal.journaled
      recipients = issue.recipients + issue.watcher_recipients
      users = User.find_all_by_mails(recipients.uniq)
      users.each do |user|
        UserMailer.issue_updated(user, journal).deliver
      end
    end
  end

  # Wrap send_notification so it defaults to true, when it's nil
  def send_notification
    return true if @send_notification.nil?
    return @send_notification
  end

  private

  # Need to clear the notification setting after each usage otherwise it might be cached
  def clear_notification
    @send_notification = true
  end

end

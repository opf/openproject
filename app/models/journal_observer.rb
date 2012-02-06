#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class JournalObserver < ActiveRecord::Observer
  attr_accessor :send_notification

  def after_create(journal)
    case journal.type
    when "IssueJournal"
      if !journal.initial? && send_notification
        after_create_issue_journal(journal)
      end
    when "WikiContentJournal"
      wiki_content = journal.journaled
      wiki_page = wiki_content.page

      if journal.initial?
        if Setting.notified_events.include?('wiki_content_added')
          (wiki_content.recipients + wiki_page.wiki.watcher_recipients).uniq.each do |recipient|
            Mailer.deliver_wiki_content_added(wiki_content, recipient)
          end
        end
      else
        if Setting.notified_events.include?('wiki_content_updated')
          (wiki_content.recipients + wiki_page.wiki.watcher_recipients + wiki_page.watcher_recipients).uniq.each do |recipient|
            Mailer.deliver_wiki_content_updated(wiki_content, recipient)
          end
        end
      end
    end
    clear_notification
  end

  def after_create_issue_journal(journal)
    if Setting.notified_events.include?('issue_updated') ||
        (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
        (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
        (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
      issue = journal.issue
      (issue.recipients + issue.watcher_recipients).uniq.each do |recipient|
        Mailer.deliver_issue_edit(journal, recipient)
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

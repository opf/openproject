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

class JournalObserver < ActiveRecord::Observer
  attr_accessor :send_notification

  def after_create(journal)
    if journal.journable_type == 'WorkPackage' and !journal.initial? and send_notification
      after_create_issue_journal(journal)
    end
    clear_notification
  end

  def after_create_issue_journal(journal)
    if Setting.notified_events.include?('work_package_updated') ||
       (Setting.notified_events.include?('work_package_note_added') && journal.notes.present?) ||
       (Setting.notified_events.include?('status_updated') && journal.changed_data.has_key?(:status_id)) ||
       (Setting.notified_events.include?('work_package_priority_updated') && journal.changed_data.has_key?(:priority_id))
      issue = journal.journable
      recipients = issue.recipients + issue.watcher_recipients
      users = User.find_all_by_mails(recipients.uniq)
      users.each do |user|
        job = DeliverWorkPackageUpdatedJob.new(user.id, journal.id, User.current.id)
        Delayed::Job.enqueue job
      end
    end
  end

  # Wrap send_notification so it defaults to true, when it's nil
  def send_notification
    return true if @send_notification.nil?
    @send_notification
  end

  private

  # Need to clear the notification setting after each usage otherwise it might be cached
  def clear_notification
    @send_notification = true
  end
end

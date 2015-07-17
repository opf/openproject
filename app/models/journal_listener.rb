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

class JournalListener
  OpenProject::Notifications.subscribe('journal_created') do |payload|
    distinguish_journals(payload[:journal], payload[:send_notification])
  end

  class << self
    def distinguish_journals(journal, send_notification)
      if journal.journable_type == 'WorkPackage' && send_notification && journal.initial?
        handle_create(journal.journable)
      elsif journal.journable_type == 'WorkPackage' && send_notification
        handle_update(journal)
      end
    end

    def handle_create(work_package)
      if Setting.notified_events.include?('work_package_added')
        recipients = work_package.recipients + work_package.watcher_recipients
        users = User.find_all_by_mails(recipients.uniq)

        users.each do |user|
          job = DeliverWorkPackageCreatedJob.new(user.id, work_package.id, User.current.id)

          Delayed::Job.enqueue job
        end
      end
    end

    def handle_update(journal)
      if send_update_notification?(journal)
        issue = journal.journable
        recipients = issue.recipients + issue.watcher_recipients
        users = User.find_all_by_mails(recipients.uniq)
        users.each do |user|
          job = DeliverWorkPackageUpdatedJob.new(user.id, journal.id, User.current.id)
          Delayed::Job.enqueue job
        end
      end
    end

    def send_update_notification?(journal)
      Setting.notified_events.include?('work_package_updated') ||
        notify_for_notes?(journal) ||
        notify_for_status?(journal) ||
        notify_for_priority(journal)
    end

    def notify_for_notes?(journal)
      Setting.notified_events.include?('work_package_note_added') && journal.notes.present?
    end

    def notify_for_status?(journal)
      Setting.notified_events.include?('status_updated') && journal.changed_data.has_key?(:status_id)
    end

    def notify_for_priority(journal)
      Setting.notified_events.include?('work_package_priority_updated') &&
        journal.changed_data.has_key?(:priority_id)
    end
  end
end

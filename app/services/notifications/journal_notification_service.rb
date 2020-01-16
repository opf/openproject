#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Notifications::JournalNotificationService
  class << self
    include Notifications::JournalNotifier

    def call(journal, send_mails)
      if journal.journable_type == 'WorkPackage'
        handle_work_package_journal(journal, send_mails)
      end
    end

    private

    def handle_work_package_journal(journal, send_mails)
      notify_for_wp_predecessor(journal, send_mails)
      enqueue_work_package_notification(journal, send_mails)
    end

    # Send the notification on behalf of the predecessor in case it could not send it on its own
    def notify_for_wp_predecessor(journal, send_mails)
      aggregated = find_aggregated_journal_for(journal)

      if Journal::AggregatedJournal.hides_notifications?(aggregated, aggregated.predecessor)
        aggregated_predecessor = find_aggregated_journal_for(aggregated.predecessor)
        notify_journal_complete(aggregated_predecessor, send_mails)
      end
    end

    def enqueue_work_package_notification(journal, send_mails)
      EnqueueWorkPackageNotificationJob
        .set(wait_until: delivery_time)
        .perform_later(journal.id, send_mails)
    end

    def delivery_time
      Setting.journal_aggregation_time_minutes.to_i.minutes.from_now
    end
  end
end

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

class Journals::CompletedJob < ApplicationJob
  queue_with_priority :notification

  class << self
    def schedule(journal, send_mails)
      return unless supported?(journal)

      set(wait_until: delivery_time)
        .perform_later(journal.id, journal.updated_at, send_mails)
    end

    def aggregated_event(journal)
      case journal.journable_type
      when WikiPage.name
        OpenProject::Events::AGGREGATED_WIKI_JOURNAL_READY
      when WorkPackage.name
        OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY
      when News.name
        OpenProject::Events::AGGREGATED_NEWS_JOURNAL_READY
      when Message.name
        OpenProject::Events::AGGREGATED_MESSAGE_JOURNAL_READY
      end
    end

    private

    def delivery_time
      Setting.journal_aggregation_time_minutes.to_i.minutes.from_now
    end

    def supported?(journal)
      aggregated_event(journal).present?
    end
  end

  def perform(journal_id, journal_updated_at, send_mails)
    # If the WP has been deleted, the journal will have been deleted, too.
    # The journal might also have been updated in the meantime. This happens if
    # the journable is updated a second time by the same user within the aggregation time.
    # If aggregation happened, then the job scheduled when the journal was updated the second time
    # will take care of notifying later.
    # If another user were to update the journable even within aggregation time,
    # the journal would not be altered. It is thus safe to consider the journal
    # final.
    journal = Journal.find_by(id: journal_id, updated_at: journal_updated_at)
    return unless journal

    notify_journal_complete(journal, send_mails)
  end

  private

  def notify_journal_complete(journal, send_mails)
    OpenProject::Notifications.send(self.class.aggregated_event(journal),
                                    journal:,
                                    send_mail: send_mails)
  end
end

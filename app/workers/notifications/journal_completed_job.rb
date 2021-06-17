#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Notifications::JournalCompletedJob < ApplicationJob
  queue_with_priority :notification

  def perform(journal_id, send_mails)
    journal = Journal.find_by(id: journal_id)

    # If the WP has been deleted the journal will have been deleted, too.
    # Or the journal might have been replaced
    return unless journal

    notify_journal_complete(journal, send_mails)
  end

  private

  def notify_journal_complete(journal, send_mails)
    OpenProject::Notifications.send(notification_event_type(journal),
                                    journal: journal,
                                    send_mail: send_mails)
  end

  def notification_event_type(journal)
    case journal.journable_type
    when WikiContent.name
      OpenProject::Events::AGGREGATED_WIKI_JOURNAL_READY
    when WorkPackage.name
      OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY
    else
      raise 'Unsupported journal created event type'
    end
  end
end

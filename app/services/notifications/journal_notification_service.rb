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

class Notifications::JournalNotificationService
  class << self
    def call(journal, send_mails)
      enqueue_notification(journal, send_mails) if supported?(journal)
    end

    private

    def enqueue_notification(journal, send_mails)
      Notifications::JournalCompletedJob
        .set(wait_until: delivery_time)
        .perform_later(journal.id, send_mails)
    end

    def delivery_time
      Setting.journal_aggregation_time_minutes.to_i.minutes.from_now
    end

    def supported?(journal)
      %w(WorkPackage WikiContent).include?(journal.journable_type)
    end
  end
end

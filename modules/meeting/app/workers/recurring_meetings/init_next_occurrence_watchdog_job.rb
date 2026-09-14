# frozen_string_literal: true

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

class RecurringMeetings::InitNextOccurrenceWatchdogJob < ApplicationJob
  queue_with_priority :low

  def perform
    key = RecurringMeetings::InitNextOccurrenceJob::CONCURRENCY_KEY_BASE

    RecurringMeeting
      .includes(:template)
      .joins("LEFT JOIN good_jobs ON good_jobs.concurrency_key = CONCAT('#{key}', recurring_meetings.id)")
      .where(good_jobs: { id: nil })
      .find_each do |series|
      next if series.template.draft?

      next_occurrence = series.next_occurrence

      if next_occurrence
        Rails.logger.warn { "Meeting series ##{series.id} lost its InitNextOccurrenceJob. Re-scheduling." }
        RecurringMeetings::InitNextOccurrenceJob.perform_later(series, next_occurrence)
      else
        Rails.logger.debug { "Meeting series ##{series.id} has no next occurrence. Skipping resetting init job" }
      end
    end
  end
end

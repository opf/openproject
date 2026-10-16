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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module RecurringWorkPackages
  class CreateNextService
    attr_reader :user, :series

    def initialize(user:, series:)
      @user = user
      @series = series
    end

    def call
      next_date = series.next_scheduled_date
      return ended_result if next_date.nil?

      latest = series.latest_occurrence
      result = Series.transaction { copy_into_series(latest, next_date) }

      report_failure(latest.work_package, result) if result.failure?
      result
    end

    private

    def copy_into_series(latest, next_date)
      result = WorkPackages::CopyService
        .new(user:, work_package: latest.work_package)
        .call(**copy_attributes(latest.work_package, next_date))

      if result.success?
        series.occurrences.create!(work_package: result.result,
                                   position: latest.position + 1,
                                   scheduled_date: next_date)
      end

      result
    end

    def copy_attributes(source, next_date)
      {
        status: Status.default,
        schedule_manually: true,
        send_notifications: true,
        **shifted_dates(source, next_date)
      }
    end

    def shifted_dates(source, next_date)
      days = WorkPackages::Shared::Days.for(source)
      start_date = days.soonest_working_day(next_date)

      if source.start_date && source.due_date
        { start_date:, due_date: days.due_date(start_date, source.duration) }
      elsif source.due_date
        { start_date: nil, due_date: start_date }
      else
        { start_date:, due_date: nil }
      end
    end

    def ended_result
      series.errors.add(:base, :ended)
      ServiceResult.failure(result: series, errors: series.errors)
    end

    def report_failure(work_package, result)
      notes = I18n.t("recurring_work_packages.notes.copy_failed",
                     errors: result.errors.full_messages.join(", "))

      AddWorkPackageNoteService
        .new(user: User.system, work_package:)
        .call(notes, send_notifications: false)
    end
  end
end

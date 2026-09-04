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

# Common methods for ApplyWorkingDaysChangeJobs
class ApplyWorkingDaysChangeJobBase < ApplicationJob
  include JobConcurrency

  queue_with_priority :above_normal

  good_job_control_concurrency_with(
    total_limit: 1
  )

  attr_reader :previous_working_days, :previous_non_working_days

  def perform(user_id:, previous_working_days:, previous_non_working_days:)
    @previous_working_days = previous_working_days
    @previous_non_working_days = previous_non_working_days

    user = User.find(user_id)

    User.execute_as user do
      apply_working_days_change
    end
  end

  private

  def apply_working_days_change
    fail NoMethodError, "Must be overridden in subclass"
  end

  def journal_cause
    @journal_cause ||= Journal::CausedByWorkingDayChanges.new(
      working_days: changed_days,
      non_working_days: changed_non_working_dates
    )
  end

  def changed_days
    # reverse order, so new working days map to true
    @changed_days ||= changes_between(previous_working_days, Setting.working_days)
  end

  def changed_non_working_dates
    # reverse order, as new non working dates map to false
    @changed_non_working_dates ||= changes_between(NonWorkingDay.pluck(:date), previous_non_working_days)
  end

  def changes_between(list_a, list_b)
    deleted = (list_a - list_b).index_with(false)
    added = (list_b - list_a).index_with(true)

    deleted.merge(added)
  end
end

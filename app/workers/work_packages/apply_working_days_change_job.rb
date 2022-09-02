#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class WorkPackages::ApplyWorkingDaysChangeJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(user_id:)
    user = User.find(user_id)

    each_applicable_work_package do |work_package|
      WorkPackages::UpdateService
        .new(user:, model: work_package, contract_class: EmptyContract)
        .call(duration: work_package.duration)
    end
  end

  private

  def each_applicable_work_package
    WorkPackage
      .where(ignore_non_working_days: false)
      .where.not(start_date: nil, due_date: nil)
      .order(WorkPackage.arel_table[:start_date].asc.nulls_first,
             WorkPackage.arel_table[:due_date].asc)
      .pluck(:id)
      .each do |id|
        work_package = WorkPackage.find(id)
        next unless dates_and_duration_mismatch?(work_package)

        yield work_package
      end
  end

  def dates_and_duration_mismatch?(work_package)
    # precondition: ignore_non_working_days is false
    non_working?(work_package.start_date) \
      || non_working?(work_package.due_date) \
      || wrong_duration?(work_package)
  end

  def non_working?(date)
    date && !days.working?(date)
  end

  def wrong_duration?(work_package)
    computed_duration = days.duration(work_package.start_date, work_package.due_date)
    computed_duration && work_package.duration != computed_duration
  end

  def days
    @days ||= WorkPackages::Shared::WorkingDays.new
  end
end

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

  def perform(user_id:, previous_working_days:)
    user = User.find(user_id)

    each_applicable_work_package(previous_working_days) do |work_package|
      apply_change_to_work_package(user, work_package)
    end
    each_applicable_follows_relation do |relation|
      apply_change_to_relation(user, relation)
    end
  end

  private

  def apply_change_to_work_package(user, work_package)
    WorkPackages::UpdateService
      .new(user:, model: work_package, contract_class: EmptyContract)
      .call(duration: work_package.duration) # trigger a recomputation of start and due date
  end

  def apply_change_to_relation(user, relation)
    predecessor = relation.to
    schedule_result = WorkPackages::SetScheduleService
                        .new(user:, work_package: predecessor)
                        .call

    # The SetScheduleService does not save. It has to be done by the caller.
    schedule_result.dependent_results.each do |dependent_result|
      work_package = dependent_result.result
      work_package.save
    end
  end

  def each_applicable_work_package(previous_working_days)
    changed_days = changed_days(previous_working_days)
    WorkPackage
      .covering_days_of_week(changed_days)
      .order(WorkPackage.arel_table[:start_date].asc.nulls_first,
             WorkPackage.arel_table[:due_date].asc)
      .pluck(:id)
      .each do |id|
        yield WorkPackage.find(id)
      end
  end

  def changed_days(previous_working_days)
    previous = Set.new(previous_working_days)
    current = Set.new(Setting.working_days)

    # `^` is a Set method returning a new set containing elements exclusive to
    # each other
    (previous ^ current).to_a
  end

  def each_applicable_follows_relation
    Relation
      .follows_with_delay
      .pluck(:id)
      .each do |id|
        yield Relation.find(id)
      end
  end
end

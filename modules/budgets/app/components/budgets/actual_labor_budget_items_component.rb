# frozen_string_literal: true

# -- copyright
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
# ++

class Budgets::ActualLaborBudgetItemsComponent < ApplicationComponent
  options :budget, :project

  def by_work_package_and_time_entry
    budget
      .time_entries
      .not_ongoing
      .visible(User.current)
      .group_by(&:work_package)
      .each do |work_package, time_entries|
        consolidate_time_entries(time_entries).each do |t|
          yield work_package, t
        end
      end
  end

  def entry_work_package(work_package)
    helpers.link_to_work_package work_package
  end

  def entry_hours(work_package, entry)
    link_to helpers.l_hours(entry.hours),
            cost_reports_path(work_package.project_id,
                              "fields[]": "WorkPackageId",
                              "operators[WorkPackageId]": "=",
                              "values[WorkPackageId]": work_package.id,
                              set_filter: 1)
  end

  def entry_user(entry)
    helpers.avatar(entry.principal, hide_name: false, size: :mini)
  end

  def entry_costs(entry)
    entry.costs_visible_by?(User.current) ? number_to_currency(entry.real_costs) : ""
  end

  def spent_sum
    number_to_currency(budget.spent_labor)
  end

  def view_rates_allowed?
    User.current.allowed_in_project?(:view_hourly_rates,
                                     project) ||
      User.current.allowed_in_project?(:view_own_hourly_rate,
                                       project)
  end

  private

  def consolidate_time_entries(time_entries)
    time_entries.inject(Hash.new) do |results, entry|
      result ||= results[entry.user.id.to_s] = empty_time_entry(entry)

      result.overridden_costs += entry.real_costs
      result.hours += entry.hours
      results
    end.values
  end

  def empty_time_entry(entry)
    result = TimeEntry.new(user: entry.user, overridden_costs: 0, project:)
    result.hours = 0
    result
  end
end

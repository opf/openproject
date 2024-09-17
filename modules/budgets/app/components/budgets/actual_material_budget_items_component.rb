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

class Budgets::ActualMaterialBudgetItemsComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
  options :budget, :project

  def by_work_package_and_cost_entry
    budget
      .cost_entries
      .visible(User.current)
      .includes(:cost_type)
      .group_by(&:work_package)
      .each do |work_package, cost_entries|
        consolidate_cost_entries(cost_entries).each do |c|
          yield work_package, c
        end
      end
  end

  def entry_work_package(work_package)
    helpers.link_to_work_package work_package
  end

  def entry_hours(work_package, entry)
    link_to helpers.localized_float(entry.units),
            cost_reports_path(work_package.project_id,
                              "fields[]": "WorkPackageId",
                              "operators[WorkPackageId]": "=",
                              "values[WorkPackageId]": work_package.id,
                              unit: entry.cost_type_id,
                              set_filter: 1)
  end

  def entry_type(entry)
    entry.cost_type
  end

  def entry_costs(entry)
    entry.costs_visible_by?(User.current) ? number_to_currency(entry.real_costs) : ""
  end

  def spent_sum
    number_to_currency(budget.spent_material)
  end

  def view_rates_allowed?
    User.current.allowed_in_project?(:view_cost_rates, project)
  end

  private

  def consolidate_cost_entries(cost_entries)
    cost_entries.inject(Hash.new) do |results, entry|
      result ||= results[entry.cost_type.id.to_s] = empty_cost_entry(entry)

      result.overridden_costs += entry.real_costs
      result.units += entry.units
      results
    end.values
  end

  def empty_cost_entry(entry)
    CostEntry.new(cost_type: entry.cost_type, project:, overridden_costs: 0.0, units: 0)
  end
end

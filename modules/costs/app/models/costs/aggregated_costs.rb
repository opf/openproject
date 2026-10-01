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

module Costs
  class AggregatedCosts
    include Budgets::ProjectAggregation

    def initialize(project:, current_user: User.current, date_range: nil)
      @project = project
      @current_user = current_user
      @date_range = date_range
    end

    def months
      return data_months unless @date_range

      start_month = @date_range.first.beginning_of_month
      end_month   = @date_range.last.beginning_of_month

      (start_month..end_month)
        .step(1.month)
        .to_a
        .freeze
    end

    def cost_type_names
      spent_material_by_month_and_type.keys.map(&:last).uniq
    end

    def spent_total
      spent_material + spent_labor
    end

    def spent_material
      cost_entries.effective_costs_sum
    end

    def spent_material_by_month_and_type
      cost_entries_by_month_and_type.effective_costs_sum
        .transform_keys { |(month, name)| [month.to_date, name] }
    end

    def spent_labor
      time_entries.effective_costs_sum
    end

    def spent_labor_by_month
      time_entries_by_month.effective_costs_sum.transform_keys(&:to_date)
    end

    def has_spending?
      cost_entries.exists? || time_entries.exists?
    end

    private

    def cost_entries
      scope = CostEntry
        .joins(:project)
        .merge(applicable_projects)
        .on_work_packages(budgeted_work_packages)
        .visible_costs(current_user)
      scope = scope.where(spent_on: @date_range) if @date_range
      scope
    end

    def cost_entries_by_month_and_type
      cost_entries
        .joins(:cost_type)
        .group(
          "date_trunc('month', cost_entries.spent_on)",
          "cost_types.name"
        )
        .order("cost_types.name ASC")
    end

    def time_entries
      scope = TimeEntry
        .joins(:project)
        .merge(applicable_projects)
        .on_work_packages(budgeted_work_packages)
        .visible_costs(current_user)
      scope = scope.where(spent_on: @date_range) if @date_range
      scope
    end

    def time_entries_by_month
      time_entries.group("date_trunc('month', time_entries.spent_on)")
    end

    def data_months
      labor_months    = spent_labor_by_month.keys
      material_months = spent_material_by_month_and_type.keys.map(&:first)
      (labor_months | material_months).sort.freeze
    end

    def budgeted_work_packages
      WorkPackage
        .where(project_id: applicable_projects)
        .where.associated(:budget)
    end
  end
end

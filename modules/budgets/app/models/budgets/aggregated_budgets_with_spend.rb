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

module Budgets
  class AggregatedBudgetsWithSpend
    attr_reader :project, :current_user

    def initialize(project:, current_user: User.current)
      @project = project
      @current_user = current_user
    end

    # Delegate to aggregated_budgets
    delegate :budget_count, :has_budgets?,
             :budgeted_base, :budgeted_material, :budgeted_labor, :budgeted_total,
             to: :aggregated_budgets

    # Delegate to aggregated_costs
    delegate :spent_material, :spent_labor, :spent_total,
             to: :aggregated_costs

    def spent_ratio
      @spent_ratio ||= budgeted_total.zero? ? BigDecimal("0") : spent_total / budgeted_total
    end

    def remaining
      @remaining ||= budgeted_total - spent_total
    end

    private

    def aggregated_budgets
      @aggregated_budgets ||= Budgets::AggregatedBudgets.new(project:, current_user:)
    end

    def aggregated_costs
      @aggregated_costs ||= Costs::AggregatedCosts.new(project:, current_user:)
    end
  end
end

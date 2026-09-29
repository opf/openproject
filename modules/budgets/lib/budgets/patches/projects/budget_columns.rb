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

module Budgets::Patches::Projects::BudgetColumns
  def budget_planned
    with_budget_aggregation do |aggregation|
      number_to_currency(aggregation.total_planned, precision: 0)
    end
  end

  def budget_spent
    with_budget_aggregation do |aggregation|
      number_to_currency(aggregation.total_spent, precision: 0)
    end
  end

  def budget_spent_ratio
    with_budget_aggregation do |aggregation|
      helpers.extended_progress_bar(aggregation.total_ratio,
                                    legend: aggregation.total_ratio.to_s)
    end
  end

  def budget_available
    with_budget_aggregation do |aggregation|
      number_to_currency(aggregation.total_available, precision: 0)
    end
  end

  def with_budget_aggregation
    @budget_aggregation ||= Budgets::ProjectBudgetAggregation.new(project)
    return unless @budget_aggregation.any?
    return unless User.current.allowed_in_project?(:view_budgets, project)

    yield @budget_aggregation
  end
end

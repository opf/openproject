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
  module Widgets
    class BudgetByCostType < Budgets::WidgetComponent
      REQUIRED_PERMISSIONS = %i[view_budgets view_cost_rates].freeze

      delegate :budget_count, :has_budgets?, :budgeted_labor, :budgeted_material_by_type,
               to: :@aggregated_budgets

      def initialize(...)
        super

        @aggregated_budgets = Budgets::AggregatedBudgets.new(project:, current_user:)
      end

      def title
        t(".title")
      end

      def chart_labels
        chart_entries.keys
      end

      def chart_data
        chart_entries.values
      end

      def has_budgets_data?
        has_budgets? && chart_data.any?
      end

      private

      def has_required_permissions?
        REQUIRED_PERMISSIONS.all? { |perm| current_user.allowed_in_project?(perm, project) }
      end

      def chart_entries
        @chart_entries ||= {}.tap do |entries|
          entries[t(:caption_labor)] = budgeted_labor.to_f if budgeted_labor.positive?
          budgeted_material_by_type.each do |name, value|
            entries[name] = value.to_f if value.positive?
          end
        end
      end
    end
  end
end

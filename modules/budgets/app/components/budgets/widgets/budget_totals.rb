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
    class BudgetTotals < Budgets::WidgetComponent
      REQUIRED_PERMISSIONS = %i[view_budgets view_cost_entries view_cost_rates view_time_entries view_hourly_rates].freeze

      delegate :has_budgets?, :budgeted_total, :spent_total, :spent_ratio, :remaining,
               to: :@aggregated_budgets_with_spend

      def initialize(...)
        super

        @aggregated_budgets_with_spend = Budgets::AggregatedBudgetsWithSpend.new(project:, current_user:)
      end

      class InlineWidget < Grids::WidgetComponent
        option :key, as: :wrapper_key
        option :title

        def call
          widget_wrapper { content }
        end

        def wrapper_arguments
          { turbo_enabled: false, half_width: true, role: "region", aria: { labelledby: "#{wrapper_key}-header" } }
        end
      end

      def title
        nil
      end

      def wrapper_arguments
        { content_padding: :none, full_width: true, border: false }
      end

      def render?
        super && project.module_enabled?(:costs) && has_budgets?
      end

      private

      def has_required_permissions?
        REQUIRED_PERMISSIONS.all? { |perm| current_user.allowed_in_project?(perm, project) }
      end

      def render_currency(value)
        color = value.negative? ? :danger : :default
        render(Primer::Beta::Truncate.new(font_weight: :bold, font_size: 1, color:)) do
          number_to_currency(value, precision: 0)
        end
      end

      def render_percentage(value)
        color = value > 100 ? :danger : :default
        render(Primer::Beta::Truncate.new(font_weight: :bold, font_size: 1, color:)) do
          number_to_percentage(value, precision: 2)
        end
      end
    end
  end
end

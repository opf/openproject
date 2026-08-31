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
  module Widgets
    class ActualCosts < Costs::WidgetComponent
      REQUIRED_PERMISSIONS = %i[view_budgets view_cost_entries view_cost_rates view_time_entries view_hourly_rates].freeze

      delegate :has_spending?, :months, :cost_type_names,
               :spent_labor_by_month, :spent_material_by_month_and_type,
               to: :@aggregated_costs

      def initialize(...)
        super

        start_date = Date.current.beginning_of_month - 11.months
        end_date   = Date.current.end_of_month
        @aggregated_costs = Costs::AggregatedCosts.new(project:, current_user:, date_range: start_date..end_date)
      end

      def render?
        super && project.module_enabled?(:budgets)
      end

      def title
        t(".title")
      end

      def chart_labels
        months.map { |month| month.to_date.iso8601 }
      end

      def chart_datasets
        return [] unless months.any?

        [labor_dataset, *material_datasets].compact
      end

      def has_spending_data?
        has_spending? && chart_datasets.any?
      end

      private

      def has_required_permissions?
        REQUIRED_PERMISSIONS.all? { |perm| current_user.allowed_in_project?(perm, project) }
      end

      def labor_dataset
        data = months.map { |month| spent_labor_by_month.fetch(month, 0).to_f }
        return unless data.sum.positive?

        { label: t(:caption_labor), data: }
      end

      def material_datasets
        cost_type_names.filter_map do |cost_type_name|
          data = months.map { |month| spent_material_by_month_and_type.fetch([month, cost_type_name], 0).to_f }
          next unless data.sum.positive?

          { label: cost_type_name, data: }
        end
      end
    end
  end
end

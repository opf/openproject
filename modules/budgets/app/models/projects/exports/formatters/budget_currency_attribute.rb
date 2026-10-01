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

module Projects::Exports::Formatters
  class BudgetCurrencyAttribute < ::Exports::Formatters::Default
    def self.apply?(attribute, _export_format)
      budget_mapping.key? attribute.to_sym
    end

    def self.budget_mapping
      {
        budget_available: :total_available,
        budget_spent: :total_spent,
        budget_planned: :total_planned
      }
    end

    def format(project, **)
      return unless project.module_enabled?("budgets") && User.current.allowed_in_project?(:view_budgets, project)

      aggregation = ::Budgets::ProjectBudgetAggregation.new(project)
      budgets_attribute = BudgetCurrencyAttribute.budget_mapping.fetch(attribute.to_sym)
      return unless aggregation && budgets_attribute

      aggregation.public_send(budgets_attribute)
    end

    def format_options
      { number_format: currency_format }
    end
  end
end

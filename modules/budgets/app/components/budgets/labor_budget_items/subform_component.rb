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
  module LaborBudgetItems
    class SubformComponent < ApplicationComponent
      extend Dry::Initializer

      option :form
      option :budget
      option :project

      attr_reader :budget_items, :template_object

      def initialize(...)
        super

        @budget_items = @budget.labor_budget_items
        # we have to assign the budget here as following methods depend on the item having an object
        @template_object = @budget_items.build.tap do |i|
          i.budget = @budget
        end
      end

      private

      def table
        @table ||= SubformTableComponent.new(
          rows: budget_items,
          form:,
          budget:,
          project:,
          table_arguments: {
            id: "labor_budget_items",
            data: { costs__budget_subform_target: "table" }
          }
        )
      end

      def template_row
        SubformRowComponent.new(row: template_object, row_counter: nil, table:, templated: true)
      end
    end
  end
end

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
    class SubformTableComponent < ::TableComponent
      options :form
      options :budget
      options :project

      columns :hours, :user, :comments, :cost

      def row_class
        SubformRowComponent
      end

      def headers
        [
          ["hours", { caption: LaborBudgetItem.human_attribute_name(:hours) }],
          ["user", { caption: LaborBudgetItem.human_attribute_name(:user) }],
          ["comments", { caption: LaborBudgetItem.human_attribute_name(:comments) }],
          ["cost", { caption: t(:label_budget) }]
        ]
      end

      def sortable?
        false
      end

      def inline_create_link
        render(
          Primer::Beta::IconButton.new(
            scheme: :invisible,
            icon: :plus,
            tooltip_direction: :e,
            aria: { label: t(:button_add_budget_item) },
            data: { action: "costs--budget-subform#addRow" },
            mt: 2
          )
        )
      end
    end
  end
end

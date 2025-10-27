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
  module BudgetItems
    class SubformRowComponent < ::RowComponent
      include Costs::NumberHelper

      COLUMN_CSS_CLASSES = { cost: "currency" }.freeze

      with_collection_parameter :row

      alias :budget_item :model

      delegate :form, :budget, :project, to: :table

      attr_reader :index, :templated

      def initialize(row_counter:, templated: false, **)
        @index = row_counter || "INDEX"
        @templated = templated

        super
      end

      def button_links
        [delete_action]
      end

      def row_css_id
        id_prefix
      end

      def row_css_class
        "cost_entry"
      end

      def column_css_classes
        COLUMN_CSS_CLASSES
      end

      def new_or_existing = budget_item.new_record? ? "new" : "existing"
      def id_or_index = budget_item.new_record? ? index : budget_item.id

      def prefix
        raise NotImplementedError
      end

      def id_prefix
        raise NotImplementedError
      end

      def name_prefix
        raise NotImplementedError
      end

      private

      def primer_text_field(name:, **)
        additional_args = { index:, label_arguments: { for: "#{id_prefix}_#{name}" } } if budget_item.new_record?
        with_form do |f|
          f.text_field(
            name:,
            visually_hide_label: true,
            **additional_args,
            **
          )
        end
      end

      def primer_select(name:, **, &)
        additional_args = { index:, label_arguments: { for: "#{id_prefix}_#{name}" } } if budget_item.new_record?
        with_form do |f|
          f.select_list(
            name:,
            visually_hide_label: true,
            include_blank: I18n.t("js.placeholders.selection"),
            **additional_args,
            **,
            &
          )
        end
      end

      def with_form(&)
        form.fields_for(prefix, budget_item) do |fields|
          render_inline_form(fields, &)
        end
      end

      def delete_action
        render(
          Primer::Beta::IconButton.new(
            scheme: :invisible,
            icon: :trash,
            tooltip_direction: :se,
            aria: { label: t(:button_delete) },
            data: { action: "costs--budget-subform#deleteRow" }
          )
        )
      end
    end
  end
end

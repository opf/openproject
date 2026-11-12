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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  module ProjectSpecificValues
    class NewValueForm < ApplicationForm
      INDENTATION = "  "

      form do |f|
        if base_errors.any?
          f.html_content do
            render(Primer::Alpha::Banner.new(scheme: :danger)) { base_errors.to_sentence }
          end
        end

        f.text_field(
          name: :label,
          label: I18n.t("custom_fields.admin.projects.new_value_dialog.name"),
          caption: I18n.t("custom_fields.admin.projects.new_value_dialog.name_caption", project: @project.name),
          value: @values[:label],
          required: true,
          autofocus: true,
          autocomplete: "off",
          validation_message: validation_message_for(:label)
        )

        if @custom_field.field_format_hierarchy?
          f.text_field(
            name: :short,
            label: I18n.t("custom_fields.admin.items.placeholder.short"),
            value: @values[:short],
            validation_message: validation_message_for(:short)
          )
        end

        if @custom_field.field_format_weighted_item_list?
          f.text_field(
            name: :weight,
            label: I18n.t("custom_fields.admin.items.placeholder.weight"),
            type: :number,
            step: :any,
            value: @values[:weight],
            required: true,
            validation_message: validation_message_for(:weight)
          )
        end

        if @custom_field.hierarchical_list?
          f.select_list(
            name: :parent_id,
            label: I18n.t("custom_fields.admin.projects.new_value_dialog.parent"),
            validation_message: validation_message_for(:parent_id)
          ) do |list|
            parent_options.each do |label, id|
              list.option(label:, value: id, selected: id.to_s == selected_parent_id.to_s)
            end
          end
        end
      end

      def initialize(custom_field:, project:, values: {}, errors: {})
        super()

        @custom_field = custom_field
        @project = project
        @values = values
        @errors = errors
      end

      private

      def parent_options
        top_level = [I18n.t("custom_fields.admin.projects.new_value_dialog.top_level"), @custom_field.hierarchy_root.id]

        [top_level, *item_options]
      end

      def item_options
        depths = { @custom_field.hierarchy_root.id => -1 }

        parent_items.map do |item|
          depths[item.id] = depths.fetch(item.parent_id) + 1
          ["#{INDENTATION * depths[item.id]}#{item.label}", item.id]
        end
      end

      def selected_parent_id
        @values[:parent_id].presence || @custom_field.hierarchy_root.id
      end

      def parent_items
        ::CustomFields::Hierarchy::HierarchicalItemService
          .new
          .get_descendants(item: @custom_field.hierarchy_root, include_self: false)
          .fmap { it.where(project_id: [nil, @project.id]) }
          .value_or([])
      end

      def validation_message_for(attribute)
        @errors.fetch(attribute, []).to_sentence.presence
      end

      def base_errors
        @errors.except(:label, :parent_id, :short, :weight).values.flatten
      end
    end
  end
end

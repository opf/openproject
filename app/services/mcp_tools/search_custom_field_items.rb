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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  class SearchCustomFieldItems < Base
    default_title "Custom Field Items"
    default_description "Access items available as values for the given custom field. Usable for list, hierarchy " \
                        "and weighted item list custom fields."

    name "search_custom_field_items"
    annotations read_only: true, idempotent: true, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[custom_field_id],
      properties: {
        custom_field_id: {
          type: "number",
          description: "The custom field for which items shall be listed."
        },
        label: {
          type: "string",
          description: "The label of the item. Matches partially and case-insensitive."
        }
      }
    )

    def call(custom_field_id:, label: nil)
      custom_field = ::CustomField.visible(current_user).find_by(id: custom_field_id)
      return list_items(custom_field, label) if custom_field&.list?
      return format_items([]) if custom_field&.hierarchy_root.nil?

      format_items(hierarchy_items(custom_field, label))
    end

    private

    def hierarchy_items(custom_field, label)
      items = flatten_hierarchy(custom_field)
      return items if label.blank?

      items.select { |item| item.label.to_s.downcase.include?(label.downcase) }
    end

    # A list field has its values as custom options, not as a hierarchy.
    def list_items(custom_field, label)
      options = custom_field.custom_options.sort_by(&:position)
      options = options.select { |option| option.value.to_s.downcase.include?(label.downcase) } if label.present?

      Success(
        {
          items: options.map { |option| { id: option.id, label: option.value, default: option.default_value? } },
          total: options.size
        }
      )
    end

    def format_items(items)
      Success(
        {
          items: items.map { |item| API::V3::CustomFields::Hierarchy::HierarchyItemRepresenter.new(item, current_user:) },
          total: items.size
        }
      )
    end

    def flatten_hierarchy(custom_field)
      ::CustomFields::Hierarchy::HierarchicalItemService
        .new
        .hashed_subtree(item: custom_field.hierarchy_root)
        .fmap { |tree| ::CustomFields::Hierarchy::HierarchicalItemAggregator.flatten_tree_hash(tree) }
        .value_or([])
    end
  end
end

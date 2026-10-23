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

module Admin
  module CustomFields
    module Projects
      class ValuesComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers

        Row = Data.define(:id, :label, :depth, :caption, :enabled)

        MAX_INDENTATION = 12

        def initialize(custom_field:, project:)
          super()

          @custom_field = custom_field
          @project = project
        end

        private

        attr_reader :custom_field, :project

        def rows
          custom_field.list? ? option_rows : item_rows
        end

        def option_rows
          custom_field.custom_options.map do |option|
            Row.new(id: option.id, label: option.value, depth: 0, caption: nil, enabled: enabled?(option))
          end
        end

        # The hierarchy root is at depth 0, so the items shown at the top level are at depth 1.
        def item_rows
          hierarchy_items.map do |item|
            Row.new(id: item.id, label: item.label, depth: item.depth - 1, caption: item_caption(item), enabled: enabled?(item))
          end
        end

        def hierarchy_items
          ::CustomFields::Hierarchy::HierarchicalItemService
            .new
            .get_descendants(item: custom_field.hierarchy_root, include_self: false)
            .value_or([])
        end

        def item_caption(item)
          parts = []
          parts << NumberFormatHelper.number_with_limit(item.weight) if custom_field.field_format_weighted_item_list?
          parts << I18n.t("custom_fields.admin.hierarchy.subitems", count: item.children_count) if item.children_count.positive?
          parts.join(" · ").presence
        end

        def enabled?(value)
          custom_field.usable_value_id?(project, value.id)
        end

        def indentation(row)
          [row.depth * 3, MAX_INDENTATION].min
        end
      end
    end
  end
end

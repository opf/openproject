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
    module Hierarchy
      class ItemsComponent < ApplicationComponent
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers
        include ItemRoutes

        def initialize(item:, new_item: nil)
          super(item)
          @new_item = new_item
        end

        def root
          @root ||= model.root? ? model : model.root
        end

        def new_item_path
          position = model.children.any? ? model.children.last.sort_order + 1 : 0
          hierarchy_item_path(model, :new_child, position:)
        end

        def reorder_alphabetical_path = hierarchy_item_path(model, :reorder_alphabetical)

        def move_item_url(item) = hierarchy_item_url(item, :move)

        def index_item_url(item) = hierarchy_item_url(item)

        def children
          list = model.children
          return list unless @new_item

          # Sort by sort order. But if there is a new item, sort it to be before the other
          # item that has the same sort order.
          list.sort { |a, b| [a.sort_order.to_i, a.id.to_i] <=> [b.sort_order.to_i, b.id.to_i] }
        end

        def item_header
          render(Primer::Beta::Breadcrumbs.new(data: { test_selector: "hierarchy-breadcrumbs" })) do |loaf|
            slices.each do |slice|
              loaf.with_item(href: slice[:href], target: nil) { slice[:label] }
            end
          end
        end

        def blank_icon
          model.root? ? "list-ordered" : "op-arrow-in"
        end

        def blank_header_text
          if custom_field.list?
            "custom_fields.admin.items.blankslate.list.title"
          elsif model.root?
            "custom_fields.admin.items.blankslate.root.title"
          else
            "custom_fields.admin.items.blankslate.item.title"
          end
        end

        def blank_description_text
          if custom_field.list?
            "custom_fields.admin.items.blankslate.list.description"
          elsif model.root?
            "custom_fields.admin.items.blankslate.root.description"
          else
            "custom_fields.admin.items.blankslate.item.description"
          end
        end

        private

        def custom_field = root.custom_field

        def branch(item)
          ::CustomFields::Hierarchy::HierarchicalItemService.new.get_branch(item:).value!
        end

        def slices
          branch(model).map do |item|
            if item.root?
              { href: hierarchy_items_path, label: custom_field.name }
            else
              { href: hierarchy_item_path(item), label: item.label }
            end
          end
        end
      end
    end
  end
end

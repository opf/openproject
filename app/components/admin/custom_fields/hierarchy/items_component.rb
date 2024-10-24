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

        property :children

        def initialize(item:, new_item_form_data: { show: false })
          super(item)
          @new_item_form_data = new_item_form_data
        end

        def item_header
          render(Primer::Beta::Breadcrumbs.new) do |loaf|
            slices.each do |slice|
              loaf.with_item(href: slice[:href], target: nil) { slice[:label] }
            end
          end
        end

        def show_new_item_form?
          @new_item_form_data[:show] || false
        end

        private

        def slices
          nodes = ::CustomFields::Hierarchy::HierarchicalItemService.new.get_branch(item: model).value!

          nodes.map do |item|
            if item.root?
              { href: custom_field_items_path(root.custom_field), label: root.custom_field.name }
            else
              { href: custom_field_item_path(root.custom_field_id, item), label: item.label }
            end
          end
        end

        def root
          return model if model.root?

          @root ||= model.root
        end
      end
    end
  end
end

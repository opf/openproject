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

module OpPrimer
  module ComponentHelpers
    def flex_layout(**, &)
      render(Primer::OpenProject::FlexLayout.new(**), &)
    end

    def grid_layout(css_class, **, &)
      render(Primer::OpenProject::GridLayout.new(css_class:, **), &)
    end

    def box_collection(**, &)
      render(OpPrimer::BoxCollectionComponent.new(**), &)
    end

    def component_collection(**, &)
      render(OpPrimer::ComponentCollectionComponent.new(**), &)
    end

    def border_box_container(**system_args, &)
      Primer::Beta::BorderBox.new(position: :relative, **system_args, &)
    end

    def border_box_row(wrapper_arguments, &)
      if container
        container.with_row(**wrapper_arguments, &)
      else
        container = border_box_container
        row = container.registered_slots[:rows][:renderable_function]
                       .bind_call(container, **wrapper_arguments)

        render(row, &)
      end
    end

    # Intended to help in building action menus with different sections, separated by dividers. Wrap all items that
    # should go into the same section into a with_item_group block. Dividers are only rendered if needed (no empty sections).
    #
    # @example
    #   def render_action_menu(menu)
    #     with_item_group { menu.with_item(label: "Item alone in section") }
    #     with_item_group do
    #       menu.with_item(label: "hidden section") if false
    #     end
    #     with_item_group do
    #       menu.with_item(label: "first in section")
    #       menu.with_item(label: "last in section")
    #     end
    #   end
    def with_item_group(menu)
      pending_divider = menu.items.any? && menu.items.last[:type] != :divider
      if pending_divider
        menu.with_divider
      end

      size_before = menu.items.size
      yield

      # undo insertion of divider, if no items were added in this section
      menu.items.pop if menu.items.size == size_before
    end
  end
end

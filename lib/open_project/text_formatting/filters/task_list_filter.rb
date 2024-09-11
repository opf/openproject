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

require "task_list/filter"

module OpenProject::TextFormatting
  module Filters
    # Overwriting the gem class to roll with our own classes
    class TaskListFilter < ::TaskList::Filter
      # Copied and adapted from parent class
      #
      # Renders the item checkbox in a span including the item state.
      #
      # Returns an HTML-safe String.
      def render_item_checkbox(item)
        %(<input type="checkbox"
        class="op-uc-list--task-checkbox"
        #{'checked="checked"' if item.complete?}
        disabled="disabled"
      />)
      end

      # Copied and adapted from parent class.
      # The added css classes are adapted or removed.
      #
      # Filters the source for task list items.
      #
      # Each item is wrapped in HTML to identify, style, and layer
      # useful behavior on top of.
      #
      # Modifications apply to the parsed document directly.
      #
      # Returns nothing.
      def filter!
        list_items(doc).reverse_each do |li|
          next if list_items(li.parent).empty?

          add_css_class(li.parent, "op-uc-list_task-list")

          outer, inner =
            if p = li.xpath(ItemParaSelector)[0]
              [p, p.inner_html]
            else
              [li, li.inner_html]
            end
          if match = inner.chomp =~ ItemPattern && $1
            item = TaskList::Item.new(match, inner)
            # prepend because we're iterating in reverse
            task_list_items.unshift item

            outer.inner_html = render_task_list_item(item)
          end
        end
      end
    end
  end
end

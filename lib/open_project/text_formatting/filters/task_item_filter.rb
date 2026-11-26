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

module OpenProject::TextFormatting
  module Filters
    class TaskItemFilter < ElementFilter
      CHECKBOX_HTML = {
        "checked" => '<input type="checkbox" class="op-uc-list--task-checkbox" disabled checked>',
        "unchecked" => '<input type="checkbox" class="op-uc-list--task-checkbox" disabled>'
      }.freeze

      match_elements "span[data-task], li[data-task], ul[data-task-list], ol[data-task-list]"

      private

      def process(element)
        case element.tag_name
        when "span" then process_span(element)
        when "li"
          element.remove_attribute("data-task")
          add_css_class(element, "op-uc-list--item_task")
        else
          element.remove_attribute("data-task-list")
          add_css_class(element, "op-uc-list_task-list")
        end
      end

      def process_span(element)
        checkbox = CHECKBOX_HTML[element["data-task"]]
        element.remove_attribute("data-task")
        return unless checkbox

        element.tag_name = "label"
        element.prepend("#{checkbox} ", as: :html)
      end

      def add_css_class(element, css_class)
        classes = element["class"].to_s.split
        element["class"] = classes.push(css_class).join(" ") unless classes.include?(css_class)
      end
    end
  end
end

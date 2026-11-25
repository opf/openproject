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

# Task-list recognition adapted from deckar01-task_list.
# The MIT License (MIT)
#
# Copyright (c) 2016 Jared Deckard
# Copyright (c) 2014 GitHub, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module OpenProject::TextFormatting
  module Filters
    class TaskListFilter < DomFilter
      MARKER = /\A(?:\s*[-+*]|\d+\.)?\s*(\[[xX[:space:]]\])(?=\s)/

      Item = Data.define(:checkbox_text, :source) do
        def complete?
          checkbox_text.casecmp?("[x]")
        end
      end

      def call
        doc.xpath(".//li").reverse_each do |list_item|
          container = list_item.at_xpath("./p[1]") || list_item
          source = container.inner_html
          match = MARKER.match(source)
          next unless match

          list_item.parent.add_class("op-uc-list_task-list")
          render_item(container, Item.new(match[1], source)) if MARKER.match?(source.chomp)
        end

        doc
      end

      private

      def render_item(container, item)
        (result[:task_list_items] ||= []).unshift(item)
        content = item.source.sub(MARKER, checkbox(item))
        container.inner_html = Nokogiri::HTML.fragment(content, "UTF-8")
      end

      def checkbox(item)
        checked = ' checked="checked"' if item.complete?
        %(<input type="checkbox" class="op-uc-list--task-checkbox"#{checked} disabled="disabled" />)
      end
    end
  end
end

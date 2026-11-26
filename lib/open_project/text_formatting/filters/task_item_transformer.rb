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
    class TaskItemTransformer
      BLOCK_ELEMENTS = %w[ul ol p div table blockquote pre figure h1 h2 h3 h4 h5 h6].freeze
      EDITOR_LIST_CLASS = "op-uc-list_task-list"
      EDITOR_LABEL_CLASS = "todo-list__label"
      HIDDEN_ELEMENTS = %w[script style svg].freeze
      LIST_ELEMENTS = %w[ul ol].freeze

      def initialize(plain_text: false)
        @plain_text = plain_text
        @generated = Set.new.compare_by_identity
        @editor_lists = Set.new.compare_by_identity
      end

      def call(env)
        node = env[:node]
        return unless node.element?

        @editor_lists << node if node.classes.include?(EDITOR_LIST_CLASS)
        strip_task_attributes(node)
        return unless node.name == "li"

        checkbox = markdown_checkbox(node)
        editor = checkbox.nil?
        checkbox ||= editor_checkbox(node)
        build_task(node, checkbox, separate: editor) if checkbox
      end

      private

      def strip_task_attributes(node)
        return if @generated.include?(node)

        node.remove_attribute("data-task")
        node.remove_attribute("data-task-list")
      end

      def markdown_checkbox(item)
        first = item.element_children.first
        first if checkbox?(first)
      end

      def editor_checkbox(item)
        labels = own_elements(item).select { it.name == "label" && editor_label?(it, item) }
        checkbox = labels.lazy.filter_map { |label| own_elements(label).find { checkbox?(it) } }.first
        return unless checkbox

        unwrap_editor_markup(item, labels, checkbox)
        checkbox
      end

      def own_elements(node)
        node.element_children.flat_map do |child|
          LIST_ELEMENTS.include?(child.name) ? [] : [child, *own_elements(child)]
        end
      end

      def editor_label?(label, item)
        label.classes.include?(EDITOR_LABEL_CLASS) || item.ancestors.any? { @editor_lists.include?(it) }
      end

      def unwrap_editor_markup(item, labels, checkbox)
        description = checkbox.next_element
        labels.each { unwrap(it) }
        unwrap(description) if description&.name == "span"
        item.prepend_child(checkbox.unlink)
      end

      def unwrap(node)
        node.replace(node.children)
      end

      def checkbox?(node)
        node&.name == "input" && node["type"]&.downcase == "checkbox"
      end

      def build_task(item, checkbox, separate:)
        content = task_content(checkbox)
        checked = checkbox.key?("checked")

        if content.none? { visible_text?(it) }
          write_bare_marker(checkbox, content, checked)
        elsif @plain_text
          write_text_marker(strip_leading_whitespace(content), checked, separate:)
        else
          wrap_in_label_span(item, strip_leading_whitespace(content), checked)
        end
        checkbox.unlink
      end

      def write_bare_marker(checkbox, content, checked)
        content.each { it.unlink if blank_text?(it) }
        checkbox.add_previous_sibling(text_node(marker(checked), checkbox))
      end

      def write_text_marker(content, checked, separate:)
        prefix = separate ? " " : ""
        content.first.add_previous_sibling(text_node("#{prefix}#{marker(checked)} ", content.first))
      end

      def marker(checked)
        checked ? "[x]" : "[ ]"
      end

      def task_content(checkbox)
        run = inline_siblings(checkbox)
        following = (run.last || checkbox).next_sibling
        return run if run.any? { visible_text?(it) } || following&.name != "p"

        following.children.to_a
      end

      def inline_siblings(checkbox)
        nodes = []
        node = checkbox.next_sibling
        while node && !block?(node)
          nodes << node
          node = node.next_sibling
        end
        nodes
      end

      def strip_leading_whitespace(nodes)
        while nodes.first && (blank_text?(nodes.first) || nodes.first.comment?)
          nodes.shift.unlink
        end
        nodes.first.content = nodes.first.content.lstrip if nodes.first&.text?
        nodes
      end

      def wrap_in_label_span(item, content, checked)
        span = item.document.create_element("span", "data-task" => checked ? "checked" : "unchecked")
        content.first.add_previous_sibling(span)
        content.each { span.add_child(it) }

        item["data-task"] = ""
        @generated << item << span
        mark_list(item.parent)
      end

      def mark_list(list)
        return unless list && %w[ul ol].include?(list.name)

        list["data-task-list"] = ""
        @generated << list
      end

      def block?(node)
        node.element? && BLOCK_ELEMENTS.include?(node.name)
      end

      def visible_text?(node)
        return !node.content.strip.empty? if node.text?
        return false unless node.element? && HIDDEN_ELEMENTS.exclude?(node.name)
        return node["alt"].to_s.strip.present? if node.name == "img"

        node.children.any? { visible_text?(it) }
      end

      def blank_text?(node)
        node.text? && node.content.strip.empty?
      end

      def text_node(content, near)
        Nokogiri::XML::Text.new(content, near.document)
      end
    end
  end
end

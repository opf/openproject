#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting
  module Filters
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter

      def whitelist
        base = super

        Sanitize::Config.merge(
          base,
          elements: base[:elements] + %w[macro],

          # Whitelist class and data-* attributes on all macros
          attributes: base[:attributes].deep_merge(
            'macro' => ['class', :data],
            # add styles to tables
            'figure' => ['class', 'style'],
            'table' => ['style'],
            'th' => ['style'],
            'tr' => ['style'],
            'td' => ['style']
          ),

          # Add rel attribute to prevent tabnabbing
          add_attributes: {
            'a' => { 'rel' => 'noopener noreferrer' }
          },

          # Add custom transformer logic for more complex modifications
          transformers: base[:transformers] + transformers,

          # Allow relaxed CSS styles for the given attributes
          css: ::Sanitize::Config::RELAXED[:css]
        )
      end

      private

      def transformers
        [
          todo_list_transformer
        ]
      end

      # Transformer to fix task lists in sanitization
      # Replace to do lists in tables with their markdown equivalent
      def todo_list_transformer
        lambda { |env|
          name = env[:node_name]
          table = env[:node]

          next unless name == 'table'

          table.css('label.todo-list__label').each do |label|
            checkbox = label.css('input[type=checkbox]').first
            li_node = label.ancestors.detect { |node| node.name == 'li' }

            # assign all children of the label to its parent
            # that might be the LI, or another element (code, link)
            parent = label.parent

            # CKEditor splits text nodes within task lists so that there are multiple labels
            # but only the first has a checkbox
            # e.g., - [ ] Foo [Bar](https://example.com)
            # both Foo and Bar are contained by labels
            if checkbox.nil?
              # In case we don't have a checkbox, add the content of the label
              # or it's parent in case of links directly to the node
              to_add = li_node == parent ? label.children : parent
              li_node.add_child to_add
            else
              checked = checkbox.attr('checked') == 'checked' ? 'x' : ' '
              checkbox.unlink

              # Ensure the task list text is be added as first child to the LI
              li_node.prepend_child " [#{checked}] "

              # Prepend if there is a parent in between
              if parent == li_node
                parent.add_child label.children
              else
                parent.prepend_child label.children
              end
            end
          end
        }
      end

    end
  end
end

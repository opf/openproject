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

module OpenProject
  module Common
    # @hidden
    class FilterableTreeViewPreview < Lookbook::Preview
      # @label Default
      # @display min_height 400px
      # @param expanded [Boolean] toggle
      # @param leading_icon [Boolean] toggle
      # @param trailing_icon [Boolean] toggle
      def default(expanded: true, leading_icon: true, trailing_icon: true)
        render(Primer::OpenProject::FilterableTreeView.new) do |component|
          component.with_sub_tree(label: "OpenProject",
                                  expanded: expanded) do |sub_tree|
            if leading_icon
              sub_tree.with_leading_visual_icons(label: "Foobar") do |icons|
                icons.with_expanded_icon(icon: :heart, color: :accent)
                icons.with_collapsed_icon(icon: :"heart-fill", color: :accent)
              end
            end

            sub_tree.with_leaf(label: "Website")

            sub_tree.with_sub_tree(label: "OpenProject GmbH",
                                   expanded: expanded) do |sub_tree2|
              sub_tree2.with_leaf(label: "HR")
              sub_tree2.with_leaf(label: "Development", current: true)

              if trailing_icon
                sub_tree2.with_trailing_visual_icon(icon: :"feed-heart")
              end
            end

            sub_tree.with_leaf(label: "Freedom edition")

            sub_tree.with_leaf(label: "Documentation")
          end

          component.with_leaf(label: "External project A")

          component.with_leaf(label: "External project B")
        end
      end
    end
  end
end

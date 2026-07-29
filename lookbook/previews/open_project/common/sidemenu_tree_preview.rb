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

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class SidemenuTreePreview < Lookbook::Preview
      # @label Default
      # @display min_height 450px
      # @param state [Symbol] select [current,default,filtered]
      def default(state: :current)
        render(
          Primer::OpenProject::FilterableTreeView.new(
            show_search_highlighting: false,
            classes: "op-sidemenu-filterable-tree",
            test_selector: "wiki-sidemenu-tree",
            include_sub_items_check_box_arguments: { hidden: true },
            filter_mode_control_arguments: { hidden: true },
            filter_input_arguments: {
              autocomplete: "off"
            }
          )
        ) do |tree|
          render_nodes(tree, state)
        end
      end

      private

      def render_nodes(tree, state)
        case state.to_sym
        when :default
          render_default_nodes(tree)
        when :filtered
          render_filtered_nodes(tree)
        else
          render_current_nodes(tree)
        end
      end

      def render_default_nodes(tree)
        tree.with_sub_tree(
          label: "Wiki",
          href: "/projects/demo/wiki/wiki",
          expanded: false,
          select_variant: :none
        ) do |wiki|
          wiki.with_leaf(label: "Glossary", href: "/projects/demo/wiki/glossary", select_variant: :none)
          wiki.with_leaf(label: "Release notes", href: "/projects/demo/wiki/release-notes", select_variant: :none)
        end

        tree.with_leaf(label: "Onboarding", href: "/projects/demo/wiki/onboarding", select_variant: :none)
      end

      def render_current_nodes(tree)
        tree.with_sub_tree(
          label: "Wiki",
          href: "/projects/demo/wiki/wiki",
          expanded: true,
          select_variant: :none
        ) do |wiki|
          wiki.with_sub_tree(
            label: "Onboarding guide",
            href: "/projects/demo/wiki/onboarding-guide",
            expanded: true,
            select_variant: :none
          ) do |guide|
            guide.with_leaf(
              label: "API setup",
              href: "/projects/demo/wiki/api-setup",
              current: true,
              select_variant: :none
            )
            guide.with_leaf(
              label: "Development setup",
              href: "/projects/demo/wiki/development-setup",
              select_variant: :none
            )
          end

          wiki.with_leaf(label: "Release notes", href: "/projects/demo/wiki/release-notes", select_variant: :none)
          wiki.with_leaf(
            label: "A very long wiki page title that should truncate inside the project sidemenu",
            href: "/projects/demo/wiki/long-page",
            select_variant: :none
          )
        end
      end

      def render_filtered_nodes(tree)
        tree.with_sub_tree(
          label: "Wiki",
          href: "/projects/demo/wiki/wiki",
          expanded: true,
          disabled: true,
          select_variant: :none
        ) do |wiki|
          wiki.with_sub_tree(
            label: highlighted_label("Onboarding guide"),
            href: "/projects/demo/wiki/onboarding-guide",
            expanded: true,
            select_variant: :none
          ) do |guide|
            guide.with_leaf(
              label: highlighted_label("API setup guide"),
              href: "/projects/demo/wiki/api-setup-guide",
              select_variant: :none
            )
          end
        end
      end

      def highlighted_label(label)
        ApplicationController.helpers.highlight_text_by_terms(label, %w[guide api])
      end
    end
  end
end

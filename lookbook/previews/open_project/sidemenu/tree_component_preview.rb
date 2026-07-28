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
  module Sidemenu
    class TreeComponentPreview < Lookbook::Preview
      # @label Filterable shell
      # @display width 280px min_height 160px
      def filterable_shell
        render FilterableTreeComponent.new(
          src: "/projects/demo/wiki/menu_tree",
          test_selector: "wiki-sidemenu-tree"
        )
      end

      # @label Tree fragment
      # @display width 280px min_height 320px
      # @param state [Symbol] select [default,current,filtered]
      def tree_fragment(state: :current)
        render TreeComponent.new(
          nodes: nodes_for(state),
          query_terms: query_terms_for(state)
        )
      end

      private

      def nodes_for(state)
        case state.to_sym
        when :default
          default_nodes
        when :filtered
          filtered_nodes
        else
          current_nodes
        end
      end

      def query_terms_for(state)
        state.to_sym == :filtered ? %w[guide api] : []
      end

      def default_nodes
        [
          node(
            id: 1,
            label: "Wiki",
            href: "/projects/demo/wiki/wiki",
            children: [
              node(id: 2, label: "Glossary", href: "/projects/demo/wiki/glossary"),
              node(id: 3, label: "Release notes", href: "/projects/demo/wiki/release-notes")
            ]
          ),
          node(id: 4, label: "Onboarding", href: "/projects/demo/wiki/onboarding")
        ]
      end

      def current_nodes
        [
          node(
            id: 1,
            label: "Wiki",
            href: "/projects/demo/wiki/wiki",
            expanded: true,
            children: [
              node(
                id: 2,
                label: "Onboarding guide",
                href: "/projects/demo/wiki/onboarding-guide",
                expanded: true,
                children: [
                  node(id: 3, label: "API setup", href: "/projects/demo/wiki/api-setup", current: true),
                  node(id: 4, label: "Development setup", href: "/projects/demo/wiki/development-setup")
                ]
              ),
              node(id: 5, label: "Release notes", href: "/projects/demo/wiki/release-notes"),
              node(
                id: 6,
                label: "A very long wiki page title that should truncate inside the project sidemenu",
                href: "/projects/demo/wiki/long-page"
              )
            ]
          )
        ]
      end

      def filtered_nodes
        [
          node(
            id: 1,
            label: "Wiki",
            href: "/projects/demo/wiki/wiki",
            expanded: true,
            disabled: true,
            children: [
              node(
                id: 2,
                label: "Onboarding guide",
                href: "/projects/demo/wiki/onboarding-guide",
                expanded: true,
                children: [
                  node(id: 3, label: "API setup guide", href: "/projects/demo/wiki/api-setup-guide")
                ]
              )
            ]
          )
        ]
      end

      def node(**attributes)
        TreeNode.new(**attributes)
      end
    end
  end
end

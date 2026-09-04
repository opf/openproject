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
        state = state.to_sym

        render(
          OpenProject::Sidemenu::TreeComponent.new(
            nodes: nodes_for(state),
            query_terms: query_terms_for(state)
          )
        )
      end

      private

      def nodes_for(state)
        case state
        when :default
          default_nodes
        when :filtered
          filtered_nodes
        else
          current_nodes
        end
      end

      def query_terms_for(state)
        state == :filtered ? %w[guide api] : []
      end

      def default_nodes
        [
          node("Wiki", "/projects/demo/wiki/wiki", children: [
                 node("Glossary", "/projects/demo/wiki/glossary"),
                 node("Release notes", "/projects/demo/wiki/release-notes")
               ]),
          node("Onboarding", "/projects/demo/wiki/onboarding")
        ]
      end

      def current_nodes
        [
          node("Wiki", "/projects/demo/wiki/wiki", expanded: true, children: [
                 node("Onboarding guide", "/projects/demo/wiki/onboarding-guide", expanded: true, children: [
                        node("API setup", "/projects/demo/wiki/api-setup", current: true),
                        node("Development setup", "/projects/demo/wiki/development-setup")
                      ]),
                 node("Release notes", "/projects/demo/wiki/release-notes"),
                 node(
                   "A very long wiki page title that should truncate inside the project sidemenu",
                   "/projects/demo/wiki/long-page"
                 )
               ])
        ]
      end

      def filtered_nodes
        [
          node("Wiki", "/projects/demo/wiki/wiki", expanded: true, disabled: true, children: [
                 node("Onboarding guide", "/projects/demo/wiki/onboarding-guide", expanded: true, children: [
                        node("API setup guide", "/projects/demo/wiki/api-setup-guide")
                      ])
               ])
        ]
      end

      def node(label, href, children: [], current: false, expanded: false, disabled: false)
        OpenProject::Sidemenu::TreeNode.new(
          id: href,
          label:,
          href:,
          children:,
          current:,
          expanded:,
          disabled:
        )
      end
    end
  end
end

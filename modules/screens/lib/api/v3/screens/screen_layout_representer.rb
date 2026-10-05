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

module API
  module V3
    module Screens
      # Renders a ::Screens::ResolvedScreen as the resolver API payload.
      class ScreenLayoutRepresenter < ::API::Decorators::Single
        def initialize(layout, project:, type:, show_diagnostics:)
          super(layout, current_user: User.current)
          @project = project
          @type = type
          @show_diagnostics = show_diagnostics
        end

        property :source
        property :reason
        property :context
        property :state_source, as: :stateSource
        property :sections, exec_context: :decorator, getter: ->(*) { sections }
        property :diagnostics, exec_context: :decorator, getter: ->(*) { diagnostics }

        link :self do
          { href: api_v3_paths.project_type_screen_layout(@project.id, @type.id, represented.context) }
        end

        link :project do
          { href: api_v3_paths.project(@project.id) }
        end

        link :type do
          { href: api_v3_paths.type(@type.id) }
        end

        link :screen do
          next unless represented.screen

          { href: api_v3_paths.screen(represented.screen.id) }
        end

        link :schema do
          { href: "/api/v3/work_packages/schemas/#{@project.id}-#{@type.id}" }
        end

        def _type
          "ScreenLayout"
        end

        def sections
          represented.sections.map do |section|
            { id: section[:id],
              name: section[:name],
              position: section[:position],
              fields: section[:fields].map { |field| field_payload(field) } }
          end
        end

        def field_payload(field)
          { key: field[:key],
            label: field[:label],
            position: field[:position],
            width: field[:width],
            state: field[:state] }
        end

        def diagnostics
          return {} unless @show_diagnostics

          source = represented.diagnostics
          { unavailable: source[:unavailable],
            hiddenButPlaced: source[:hidden_but_placed],
            requiredNotPlaced: source[:required_not_placed],
            notVisible: source[:not_visible],
            skipped: source[:skipped],
            emptyCreateScreen: source[:empty_create_screen],
            error: source[:error] }
        end
      end
    end
  end
end

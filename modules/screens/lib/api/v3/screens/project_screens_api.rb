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
      class ProjectScreensAPI < ::API::OpenProjectAPI
        helpers InputHelpers

        helpers do
          def diagnostics_visible?
            User.current.admin? || User.current.allowed_in_project?(:assign_screen_scheme, @project)
          end
        end

        resource :screen_scheme do
          get do
            authorize_in_project(:assign_screen_scheme, project: @project)
            assignment = ProjectScreenScheme.find_by(project_id: @project.id) ||
                         ProjectScreenScheme.new(project_id: @project.id)
            ProjectScreenSchemeRepresenter.new(assignment, current_user:)
          end

          put do
            authorize_in_project(:assign_screen_scheme, project: @project)
            body = body_hash!
            scheme_id = body[:scheme_id] || id_from_link(body, :screenScheme, "screen_schemes")

            if scheme_id.blank?
              ::Screens::SchemeService.unassign(@project)
            else
              scheme = ScreenScheme.active.find_by(id: safe_id(scheme_id).positive? ? safe_id(scheme_id) : nil)
              raise ::API::Errors::Validation.new("schemeId", "An active screen scheme is required.") unless scheme

              result = ::Screens::SchemeService.assign(@project, scheme)
              raise_service_errors(result) if result.failure?
            end

            status 204
            body false
          end
        end

        resource :types do
          route_param :type_id, type: Integer do
            resource :screens do
              route_param :context, type: String do
                get do
                  context = normalize_context!(params[:context])
                  authorize_in_project(:view_work_packages, project: @project)
                  type = @project.enabled_types.find_by(id: params[:type_id])
                  raise ::API::Errors::NotFound.new unless type

                  layout = ::Screens::Resolver.for(@project, type, context)
                  header "Cache-Control", "private"
                  ScreenLayoutRepresenter.new(layout, project: @project, type:,
                                                       show_diagnostics: diagnostics_visible?)
                end
              end
            end
          end
        end
      end
    end
  end
end

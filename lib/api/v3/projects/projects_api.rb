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

module API
  module V3
    module Projects
      class ProjectsAPI < ::API::OpenProjectAPI
        resources :projects do
          get &::API::V3::Utilities::Endpoints::SqlFallbackedIndex.new(model: Project,
                                                                       scope: -> {
                                                                         # TODO: This should be scoped to only allow actual
                                                                         # projects. But since it is an established route,
                                                                         # we keep it intact for all kinds of workspaces for 17.0.
                                                                         Project
                                                                           .includes(ProjectRepresenter.to_eager_load)
                                                                       })
                                                                  .mount

          post &::API::V3::Utilities::Endpoints::Create.new(model: Project,
                                                            params_modifier: ->(attributes) {
                                                              attributes.merge!(workspace_type: "project")
                                                            })
                                                       .mount

          mount ::API::V3::Workspaces::Schemas::WorkspaceSchemaAPI
          mount ::API::V3::Projects::CreateFormAPI

          mount API::V3::Projects::AvailableParentsAPI

          params do
            requires :id, desc: "Project id"
          end
          route_param :id do
            after_validation do
              # TODO: This should be scoped to only allow actual projects.
              # But since it and especially the NestedAPIs are established routes,
              # we keep it intact for all kinds of workspaces for 17.0.
              # This behaviour is not documented in the API docs to nudge users to switch.
              @project = if current_user.admin?
                           Project
                         else
                           Project.visible(current_user)
                         end.find(params[:id])
            end

            mount API::V3::Projects::Copy::CopyAPI
            mount API::V3::Projects::Configuration::ProjectConfigurationAPI
            mount ::API::V3::AI::TextTransformActionsByProjectAPI

            mount ::API::V3::Workspaces::InstanceApis
            mount ::API::V3::Workspaces::NestedApis
          end
        end
      end
    end
  end
end

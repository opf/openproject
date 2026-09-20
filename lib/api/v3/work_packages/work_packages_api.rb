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

require "api/v3/work_packages/work_package_representer"

module API
  module V3
    module WorkPackages
      class WorkPackagesAPI < ::API::OpenProjectAPI
        resources :work_packages do
          helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers

          # The endpoint needs to be mounted before the GET :work_packages/:id.
          # Otherwise, the matcher for the :id also seems to match available_projects.
          # This is also true when the :id param is declared to be of type: Integer.
          mount ::API::V3::WorkPackages::AvailableProjectsOnCreateAPI
          mount ::API::V3::WorkPackages::Schema::WorkPackageSchemasAPI

          get do
            authorize_in_any_work_package(:view_work_packages)

            call = raise_invalid_query_on_service_failure do
              WorkPackageCollectionFromQueryParamsService
                .new(current_user)
                .call(params)
            end

            call.result
          end

          post(&::API::V3::Utilities::Endpoints::Create.new(model: WorkPackage,
                                                            parse_service: WorkPackages::ParseParamsService,
                                                            params_modifier: ->(attributes) {
                                                              attributes[:send_notifications] = notify_according_to_params
                                                              attributes
                                                            })
                                                       .mount)

          route_param :id, type: String, desc: "Work package ID or semantic identifier (e.g. PROJ-42)" do
            helpers WorkPackagesSharedHelpers

            helpers do
              attr_reader :work_package
            end

            after_validation do
              @work_package = WorkPackage.visible.find_by_display_id(declared_params[:id])
              @work_package ||= WorkPackage.visible_in_trash.find_by_display_id(declared_params[:id]) if trash_available?

              raise API::Errors::NotFound.new(model: :work_package) unless @work_package
            end

            get &API::V3::WorkPackages::ShowEndPoint.new(model: WorkPackage).mount

            patch &::API::V3::WorkPackages::UpdateEndPoint.new(model: WorkPackage,
                                                               parse_service: ::API::V3::WorkPackages::ParseParamsService,
                                                               params_modifier: ->(attributes) {
                                                                 attributes[:send_notifications] = notify_according_to_params
                                                                 attributes
                                                               })
                                                          .mount

            delete do
              raise API::Errors::NotFound.new(model: :work_package) if trash_available? && @work_package.trashed?

              service = if trash_available?
                          ::WorkPackages::TrashService
                        else
                          ::WorkPackages::DeleteService
                        end
              call = service.new(user: current_user, model: @work_package).call
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors) unless call.success?

              status 204
            end

            post :move_to_trash do
              call_trash_service(::WorkPackages::TrashService)
            end

            post :restore do
              call_trash_service(::WorkPackages::RestoreService)
            end

            delete :delete_permanently do
              call = ::WorkPackages::PurgeService.new(user: current_user, model: @work_package).call
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors) unless call.success?

              status 204
            end

            mount ::API::V3::WorkPackages::WatchersAPI
            mount ::API::V3::Activities::ActivitiesByWorkPackageAPI
            mount ::API::V3::Attachments::AttachmentsByWorkPackageAPI
            mount ::API::V3::Repositories::RevisionsByWorkPackageAPI
            mount ::API::V3::WorkPackages::UpdateFormAPI
            mount ::API::V3::WorkPackages::AvailableAssigneesAPI
            mount ::API::V3::WorkPackages::AvailableProjectsOnEditAPI
            mount ::API::V3::WorkPackages::AvailableRelationCandidatesAPI
            mount ::API::V3::WorkPackages::WorkPackageRelationsAPI
            mount ::API::V3::Reminders::RemindersByWorkPackageAPI
            mount ::API::V3::EmojiReactions::EmojiReactionsByWorkPackageCommentsAPI
          end

          mount ::API::V3::WorkPackages::CreateFormAPI
        end

        helpers do
          def trash_available?
            ::WorkPackages::TrashFeature.enabled?
          end

          def call_trash_service(service)
            call = service.new(user: current_user, model: @work_package).call
            fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors) unless call.success?

            ::API::V3::WorkPackages::WorkPackageRepresenter.new(call.result, current_user:)
          end
        end
      end
    end
  end
end

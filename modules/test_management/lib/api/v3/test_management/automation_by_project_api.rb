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

module API
  module V3
    module TestManagement
      class AutomationByProjectAPI < ::API::OpenProjectAPI
        UPLOAD_PERMISSIONS = %i[upload_test_results add_test_runs].freeze

        namespace :test_management do
          helpers CrudHelpers
          helpers LibraryHelpers
          helpers RunHelpers
          helpers IngestHelpers
          helpers CiConnectionHelpers

          namespace :settings do
            get do
              authorize_in_project(%i[view_test_cases manage_test_management], project: @project)
              ProjectSettingRepresenter.new(::TestManagement::ProjectSetting.for_project(@project), current_user:)
            end

            patch do
              body = request_body
              attributes = ::TestManagement::ProjectSetting::FEATURES.each_with_object({}) do |feature, hash|
                hash["enable_#{feature}"] = body["enable#{feature.camelize}"] if body.key?("enable#{feature.camelize}")
              end
              attributes["display_prefix"] = body["displayPrefix"] if body.key?("displayPrefix")
              attributes["folder_tree_layout"] = body["folderTreeLayout"] if body.key?("folderTreeLayout")
              call = ::TestManagement::ProjectSettings::UpdateService
                       .new(user: current_user, model: ::TestManagement::ProjectSetting.for_project(@project))
                       .call(attributes)
              respond_with_call!(call, ProjectSettingRepresenter)
            end
          end

          namespace :folders do
            get do
              authorize_in_project(%i[view_test_cases], project: @project)
              FolderCollectionRepresenter.new(@project.tm_suites.ordered.to_a,
                                              self_link: api_v3_paths.project_test_management_folders(@project.id),
                                              current_user:)
            end

            post do
              call = ::TestManagement::Suites::CreateService.new(user: current_user)
                                                            .call(folder_attributes.merge(project: @project))
              respond_with_call!(call, FolderRepresenter, status_code: 201)
            end
          end

          namespace :cases do
            get do
              authorize_in_project(%i[view_test_cases], project: @project)
              query = ::TestManagement::TestCasesQuery.new(
                @project,
                { suite_id: params[:folderId], q: params[:search], status: params[:status],
                  priority: params[:priority], automated: params[:automated] }.compact_blank
              )
              filters = params.slice(:folderId, :search, :status, :priority, :automated).to_h
              TestCaseCollectionRepresenter.new(query.results.includes(:steps).order(:id),
                                                self_link: api_v3_paths.project_test_management_cases(@project.id),
                                                query_params: filters,
                                                current_user:, **offset_page_params)
            end

            post do
              call = ::TestManagement::TestCases::CreateService.new(user: current_user)
                                                               .call(case_attributes.merge(project: @project))
              respond_with_call!(call, TestCaseRepresenter, status_code: 201)
            end
          end

          namespace :automation do
            namespace :results do
              post do
                authorize_in_project(UPLOAD_PERMISSIONS, project: @project)
                ingest!
              end
            end
          end

          namespace :ci_connections do
            get do
              authorize_in_project(%i[manage_test_ci] + UPLOAD_PERMISSIONS, project: @project)
              CiConnectionCollectionRepresenter.new(@project.tm_ci_connections.ordered.to_a,
                                                    self_link: api_v3_paths.project_test_management_ci_connections(@project.id),
                                                    current_user:)
            end

            post do
              call = ::TestManagement::CiConnections::CreateService.new(user: current_user)
                                                                   .call(ci_connection_attributes.merge(project: @project))
              respond_with_call!(call, CiConnectionRepresenter, status_code: 201)
            end
          end

          namespace :ci_triggers do
            post do
              authorize_in_project(%i[trigger_test_automation], project: @project)
              find = lambda do |scope, key|
                next nil if params[key].blank?

                scope.find_by(id: params[key].to_s.to_i) || raise(::API::Errors::NotFound.new)
              end
              connection = ::TestManagement::CiConnection.lookup(@project, params[:connection].to_s)
              raise ::API::Errors::UnprocessableContent.new(I18n.t("test_management.api.unknown_connection")) unless connection

              call = ::TestManagement::CiTriggers::TriggerService.new(user: current_user).call(
                project: @project, connection:, mode: params[:mode].presence || "new_run",
                run: find.(@project.tm_test_runs, :runId),
                suite: find.(@project.tm_suites, :suiteId),
                test_case: find.(@project.tm_test_cases, :testCaseId),
                ref: params[:ref], name: params[:name]
              )
              ensure_success!(call)
              status(call.result.triggered? ? 201 : 502)
              CiTriggerRepresenter.new(call.result, current_user:)
            end
          end

          namespace :runs do
            get do
              authorize_in_project(%i[view_test_runs] + UPLOAD_PERMISSIONS, project: @project)
              runs = @project.tm_test_runs.newest_first
              runs = runs.where(external_ref: params[:externalRef]) if params[:externalRef].present?
              runs = runs.where(state: params[:state]) if params[:state].present?
              runs = runs.where(source: params[:source]) if params[:source].present?
              runs = runs.where("LOWER(tm_test_runs.name) = ?", params[:name].to_s.downcase) if params[:name].present?
              RunCollectionRepresenter.new(::TestManagement::TestRun.preload_stats(runs.limit(500)),
                                           self_link: api_v3_paths.project_test_management_runs(@project.id),
                                           query: params.slice(:externalRef, :state, :source, :name).to_h,
                                           current_user:)
            end

            post do
              call = ::TestManagement::TestRuns::CreateService.new(user: current_user)
                                                              .call(run_attributes.merge(project: @project))
              respond_with_call!(call, RunRepresenter, status_code: 201)
            end

            route_param :run_id, type: Integer, desc: "Test run ID" do
              namespace :results do
                post do
                  authorize_in_project(UPLOAD_PERMISSIONS, project: @project)
                  ingest!(run_id: params[:run_id])
                end
              end
            end
          end
        end
      end
    end
  end
end

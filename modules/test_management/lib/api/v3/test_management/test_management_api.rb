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
      class TestManagementAPI < ::API::OpenProjectAPI
        VIEW_PERMISSIONS = %i[view_test_runs upload_test_results].freeze
        CI_CONNECTION_PERMISSIONS = %i[manage_test_ci upload_test_results add_test_runs].freeze

        helpers CrudHelpers
        helpers LibraryHelpers
        helpers RunHelpers
        helpers AssistantProviderHelpers
        helpers CiConnectionHelpers

        helpers do
          def find_visible_run!(id)
            run = ::TestManagement::TestRun.includes(:project, :connection, run_cases: :test_case).find_by(id:)
            raise ::API::Errors::NotFound.new unless run && allowed_any?(VIEW_PERMISSIONS, run.project)

            run
          end

          def transition!(service_class, run, **)
            call = service_class.new(user: current_user, model: run).call(**)
            ensure_success!(call)
            status 200
            RunRepresenter.new(run.reload, current_user:)
          end

          def completion_source
            params[:completionSource] == "manual" ? "manual" : "automation"
          end
        end

        namespace :test_management do
          namespace :assistant do
            namespace :providers do
              get do
                provider_admin!
                elements = ::TestManagement::AssistantProvider.ordered.map { assistant_provider_json(it) }
                { _type: "Collection", total: elements.size, count: elements.size,
                  _links: { self: { href: api_v3_paths.test_management_assistant_providers } },
                  _embedded: { elements: } }
              end

              post do
                provider_admin!
                provider = save_assistant_provider!(::TestManagement::AssistantProvider.new, request_body)
                status 201
                assistant_provider_json(provider)
              end

              route_param :provider_id, type: Integer, desc: "Provider ID" do
                get do
                  provider_admin!
                  assistant_provider_json(find_assistant_provider!(params[:provider_id]))
                end

                patch do
                  provider_admin!
                  assistant_provider_json(save_assistant_provider!(find_assistant_provider!(params[:provider_id]),
                                                                   request_body))
                end

                delete do
                  provider_admin!
                  find_assistant_provider!(params[:provider_id]).destroy!
                  ::TestManagement::AssistantProvider.ensure_default!
                  status 204
                  body false
                end

                post :default do
                  provider_admin!
                  provider = find_assistant_provider!(params[:provider_id])
                  provider.make_default!
                  status 200
                  assistant_provider_json(provider.reload)
                end

                post :test_connection do
                  provider_admin!
                  result = ::TestManagement::Assistant::AI::ConnectionTest
                             .new(find_assistant_provider!(params[:provider_id]).config).call
                  status 200
                  { _type: "TestManagementAssistantProviderTest", ok: result.ok?, message: result.message,
                    errorKind: result.error_kind, models: result.models }
                end
              end
            end
          end

          namespace :folders do
            route_param :id, type: Integer, desc: "Folder ID" do
              after_validation do
                @folder = ::TestManagement::Suite.includes(:project).find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless @folder && allowed_any?(%i[view_test_cases], @folder.project)
              end

              get do
                FolderRepresenter.new(@folder, current_user:)
              end

              patch do
                call = ::TestManagement::Suites::UpdateService.new(user: current_user, model: @folder)
                                                              .call(folder_attributes)
                respond_with_call!(call, FolderRepresenter)
              end

              delete do
                respond_deleted!(::TestManagement::Suites::DeleteService.new(user: current_user, model: @folder).call)
              end
            end
          end

          namespace :cases do
            route_param :id, type: Integer, desc: "Test case ID" do
              after_validation do
                @case = ::TestManagement::TestCase.includes(:project, :steps).find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless @case && allowed_any?(%i[view_test_cases], @case.project)
              end

              get do
                TestCaseRepresenter.new(@case, current_user:)
              end

              patch do
                ensure_lock_version!(@case)
                call = ::TestManagement::TestCases::UpdateService.new(user: current_user, model: @case)
                                                                 .call(case_attributes(@case))
                respond_with_call!(call, TestCaseRepresenter)
              rescue ActiveRecord::StaleObjectError
                raise ::API::Errors::Conflict.new(message: I18n.t("test_management.api.stale_case"))
              end

              delete do
                respond_deleted!(::TestManagement::TestCases::DeleteService.new(user: current_user, model: @case).call)
              end
            end
          end

          namespace :runs do
            route_param :id, type: Integer, desc: "Test run ID" do
              after_validation do
                @run = find_visible_run!(params[:id])
              end

              get do
                RunRepresenter.new(@run, current_user:, with_cases: true)
              end

              patch do
                call = ::TestManagement::TestRuns::UpdateService.new(user: current_user, model: @run).call(run_attributes)
                respond_with_call!(call, RunRepresenter)
              end

              delete do
                respond_deleted!(::TestManagement::TestRuns::DeleteService.new(user: current_user, model: @run).call)
              end

              post :complete do
                transition!(::TestManagement::TestRuns::CompleteService, @run, completion_source:)
              end

              post :cancel do
                transition!(::TestManagement::TestRuns::CancelService, @run, completion_source:)
              end

              post :reopen do
                transition!(::TestManagement::TestRuns::ReopenService, @run)
              end

              get :imports do
                unpaginated_collection(ImportRepresenter, @run.automation_imports.newest_first,
                                       self_link: api_v3_paths.test_management_run_imports(@run.id))
              end

              namespace :iterations do
                get do
                  iterations = ::TestManagement::TestRunIteration.preload_stats(@run.iterations.to_a, @run)
                  unpaginated_collection(IterationRepresenter, iterations,
                                         self_link: api_v3_paths.test_management_run_iterations(@run.id))
                end

                post do
                  name = params[:name] || params.dig(:iteration, :name)
                  call = ::TestManagement::TestRunIterations::StartService.new(user: current_user, run: @run).call(name:)
                  ensure_success!(call)
                  status 201
                  IterationRepresenter.new(call.result, current_user:)
                end

                route_param :number, type: Integer, desc: "Iteration number" do
                  get do
                    iteration = @run.iterations.find_by(number: params[:number])
                    raise ::API::Errors::NotFound.new unless iteration

                    IterationRepresenter.new(iteration, current_user:)
                  end
                end
              end
            end
          end

          namespace :run_cases do
            route_param :id, type: Integer, desc: "Test run case ID" do
              after_validation do
                @run_case = ::TestManagement::TestRunCase.includes(test_run: :project).find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless @run_case && allowed_any?(VIEW_PERMISSIONS, @run_case.project)
              end

              get do
                RunCaseRepresenter.new(@run_case, current_user:)
              end

              post :results do
                body = request_body
                if body["status"].blank? && body["comment"].blank?
                  raise ::API::Errors::UnprocessableContent.new(I18n.t("test_management.api.nothing_to_record"))
                end

                call = ::TestManagement::RunCases::UpdateService.new(user: current_user, model: @run_case)
                                                                .call({ status: body["status"],
                                                                        comment: body["comment"] }.compact)
                ensure_success!(call)
                status 201
                ResultRepresenter.new(@run_case.results.order(:id).last, current_user:)
              end
            end
          end

          namespace :results do
            route_param :id, type: Integer, desc: "Test result ID" do
              get do
                result = ::TestManagement::TestResult.includes(:user, :iteration, run_case: { test_run: :project })
                                                     .find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless result && allowed_any?(VIEW_PERMISSIONS, result.run_case.project)

                ResultRepresenter.new(result, current_user:)
              end
            end
          end

          namespace :ci_connections do
            route_param :id, type: Integer, desc: "CI connection ID" do
              get do
                CiConnectionRepresenter.new(visible_ci_connection!(params[:id], CI_CONNECTION_PERMISSIONS), current_user:)
              end

              patch do
                connection = visible_ci_connection!(params[:id], CI_CONNECTION_PERMISSIONS)
                call = ::TestManagement::CiConnections::UpdateService.new(user: current_user, model: connection)
                                                                     .call(ci_connection_attributes)
                respond_with_call!(call, CiConnectionRepresenter)
              end

              delete do
                connection = visible_ci_connection!(params[:id], CI_CONNECTION_PERMISSIONS)
                respond_deleted!(::TestManagement::CiConnections::DeleteService.new(user: current_user, model: connection).call)
              end
            end
          end

          namespace :automation do
            namespace :imports do
              route_param :id, type: Integer, desc: "Automation import ID" do
                get do
                  import = ::TestManagement::AutomationImport.includes(:project).find_by(id: params[:id])
                  raise ::API::Errors::NotFound.new unless import && allowed_any?(VIEW_PERMISSIONS, import.project)

                  ImportRepresenter.new(import, current_user:)
                end
              end
            end
          end
        end
      end
    end
  end
end

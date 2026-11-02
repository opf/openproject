# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Global test management resources (mounted in API::V3::Root):
      #   GET  /api/v3/test_management/runs/:id               run (+ cases)
      #   POST /api/v3/test_management/runs/:id/complete      complete (freeze statuses, write case history)
      #   POST /api/v3/test_management/runs/:id/cancel        cancel
      #   GET  /api/v3/test_management/runs/:id/imports       automation uploads of the run
      #   GET  /api/v3/test_management/runs/:id/iterations    iterations (history, per-iteration pass rate)
      #   POST /api/v3/test_management/runs/:id/iterations    start a new iteration (add_test_runs)
      #   GET  /api/v3/test_management/runs/:id/iterations/:number
      #   GET  /api/v3/test_management/ci_connections/:id     CI connection (token never included)
      #   PATCH|DELETE /api/v3/test_management/ci_connections/:id  update / delete (manage_test_ci, 0016)
      #   GET|POST /api/v3/test_management/runs/:id/attachments
      #   GET  /api/v3/test_management/run_cases/:id          run case with results
      #   POST /api/v3/test_management/run_cases/:id/results  record a manual result with step results (0020)
      #   GET  /api/v3/test_management/results/:id             one result: error + step results (0020)
      #   GET|POST /api/v3/test_management/run_cases/:id/attachments
      #   GET  /api/v3/test_management/automation/imports/:id
      #   GET|PATCH|DELETE /api/v3/test_management/milestones/:id
      #   POST /api/v3/test_management/milestones/:id/start|complete|reopen
      #   GET  /api/v3/test_management/assistant/generations/:id     own generation with drafts (0014)
      #   POST /api/v3/test_management/assistant/generations/:id/save  save drafts as test cases
      #   GET  /api/v3/test_management/assistant/providers           saved AI providers (0021; admins: full,
      #                                                              users with use_test_assistant: names and models)
      #   POST /api/v3/test_management/assistant/providers           add (admin)
      #   GET|PATCH|DELETE /api/v3/test_management/assistant/providers/:id  (PATCH, DELETE: admin)
      #   POST /api/v3/test_management/assistant/providers/:id/default      make default (admin)
      class TestManagementAPI < ::API::OpenProjectAPI
        VIEW_PERMISSIONS = %i[view_test_runs upload_test_results].freeze
        CI_CONNECTION_PERMISSIONS = %i[manage_test_ci upload_test_results add_test_runs].freeze

        helpers do
          def find_visible_run!(id)
            run = ::TestManagement::TestRun.includes(:project, :connection, :milestone, :test_plan,
                                                     run_cases: :test_case).find_by(id:)
            raise ::API::Errors::NotFound.new unless run && allowed_any?(VIEW_PERMISSIONS, run.project)

            run
          end

          def allowed_any?(permissions, project)
            permissions.any? { |permission| current_user.allowed_in_project?(permission, project) }
          end

          def transition!(service_class, run, **)
            call = service_class.new(user: current_user, model: run).call(**)
            if call.success?
              # Grape answers POST with 201 by default; a state transition creates nothing.
              status 200
              return RunRepresenter.new(run.reload, current_user:)
            end

            symbols = call.errors.details[:base].pluck(:error)
            raise ::API::Errors::Unauthorized if symbols.include?(:error_unauthorized)

            message = call.errors.full_messages.join(" ")
            raise ::API::Errors::Conflict.new(message:) if symbols.include?(:tm_invalid_transition)

            raise ::API::Errors::UnprocessableContent.new(message)
          end
        end

        helpers MilestoneHelpers
        helpers PlanHelpers
        helpers AssistantHelpers
        helpers AssistantProviderHelpers
        helpers CiConnectionHelpers

        namespace :test_management do
          namespace :assistant do
            # 0021: saved AI providers. The API key is write-only (apiKey); responses carry apiKeySet.
            namespace :providers do
              get do
                provider_reader!
                choice = ::TestManagement::Assistant::ProviderChoice.for(current_user)
                elements = ::TestManagement::AssistantProvider.ordered.map { assistant_provider_json(it, choice) }
                { _type: "Collection", total: elements.size, count: elements.size,
                  _links: { self: { href: api_v3_paths.test_management_assistant_providers } },
                  _embedded: { elements: } }
              end

              post do
                provider_admin!
                provider = save_assistant_provider!(::TestManagement::AssistantProvider.new, assistant_body)
                status 201
                assistant_provider_json(provider)
              end

              route_param :provider_id, type: Integer, desc: "Provider ID" do
                get do
                  provider_reader!
                  provider = find_assistant_provider!(params[:provider_id])
                  assistant_provider_json(provider, ::TestManagement::Assistant::ProviderChoice.for(current_user))
                end

                patch do
                  provider_admin!
                  assistant_provider_json(save_assistant_provider!(find_assistant_provider!(params[:provider_id]),
                                                                   assistant_body))
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
              end
            end

            namespace :generations do
              route_param :generation_id, type: Integer, desc: "Generation ID" do
                get do
                  AssistantGenerationRepresenter.new(find_own_generation!(params[:generation_id]), current_user:)
                end

                # Saves drafts as test cases (status draft). Body (all optional):
                #   { drafts: [...edited drafts...] (default: all drafts), suiteId, labels: [...] }
                post :save do
                  generation = find_own_generation!(params[:generation_id])
                  raise ::API::Errors::Conflict.new(message: "The generation is not done.") unless generation.done?

                  body = assistant_body
                  drafts = body.key?("drafts") ? api_drafts(body["drafts"]) : generation.draft_list
                  result = ::TestManagement::Assistant::SaveDraftsService.new(user: current_user, generation:).call(
                    drafts:,
                    suite_id: body.key?("suiteId") ? body["suiteId"] : generation.suite_id,
                    label_names: body.key?("labels") ? Array(body["labels"]) : generation.label_names
                  )
                  raise ::API::Errors::UnprocessableContent.new(result.errors.join(" ")) unless result.success?

                  status 201
                  {
                    _type: "TestManagementAssistantSaveResult",
                    savedCaseIds: result.cases.map(&:id),
                    testCases: result.cases.map { |c| { id: c.id, title: c.title } },
                    _links: {
                      generation: { href: api_v3_paths.test_management_assistant_generation(generation.id) }
                    }
                  }
                end
              end
            end
          end

          namespace :milestones do
            route_param :id, type: Integer, desc: "Milestone ID" do
              after_validation do
                @milestone = ::TestManagement::Milestone.includes(:project).find_by(id: params[:id])
                unless @milestone && current_user.allowed_in_project?(:view_test_runs, @milestone.project)
                  raise ::API::Errors::NotFound.new
                end

                milestones_enabled!(@milestone.project)
              end

              get do
                MilestoneRepresenter.new(@milestone, current_user:)
              end

              patch do
                call = ::TestManagement::Milestones::UpdateService
                         .new(user: current_user, model: @milestone)
                         .call(milestone_attributes)
                milestone_result!(call, 200)
              end

              delete do
                call = ::TestManagement::Milestones::DeleteService.new(user: current_user, model: @milestone).call
                if call.success?
                  status 204
                  body false
                else
                  milestone_result!(call, 204)
                end
              end

              { start: ::TestManagement::Milestones::StartService,
                complete: ::TestManagement::Milestones::CompleteService,
                reopen: ::TestManagement::Milestones::ReopenService }.each do |action, service|
                namespace action do
                  post do
                    milestone_result!(service.new(user: current_user, model: @milestone).call, 200)
                  end
                end
              end
            end
          end

          namespace :configuration_groups do
            route_param :id, type: Integer, desc: "Configuration group ID" do
              get do
                group = ::TestManagement::ConfigurationGroup.includes(:project, :configurations).find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless group &&
                                                         current_user.allowed_in_project?(:view_test_cases, group.project)

                ConfigurationGroupRepresenter.new(group, current_user:)
              end

              patch do
                group = ::TestManagement::ConfigurationGroup.includes(:project).find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless group

                call = ::TestManagement::ConfigurationGroups::UpdateService
                         .new(user: current_user, model: group)
                         .call(name: plan_request_body["name"])
                raise ::API::Errors::Unauthorized if call.errors.details[:base].pluck(:error).include?(:error_unauthorized)
                raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

                ConfigurationGroupRepresenter.new(call.result.reload, current_user:)
              end

              delete do
                group = ::TestManagement::ConfigurationGroup.includes(:project).find_by(id: params[:id])
                raise ::API::Errors::NotFound.new unless group

                call = ::TestManagement::ConfigurationGroups::DeleteService.new(user: current_user, model: group).call
                raise ::API::Errors::Unauthorized if call.errors.details[:base].pluck(:error).include?(:error_unauthorized)
                raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

                status 204
                body false
              end
            end
          end

          namespace :plans do
            route_param :id, type: Integer, desc: "Test plan ID" do
              after_validation do
                @plan = find_visible_plan!(params[:id])
              end

              get do
                PlanRepresenter.new(@plan, current_user:)
              end

              patch do
                plan_result!(
                  ::TestManagement::Plans::UpdateService.new(user: current_user, model: @plan).call(plan_attributes),
                  200
                )
              end

              delete do
                call = ::TestManagement::Plans::DeleteService.new(user: current_user, model: @plan).call
                if call.success?
                  status 204
                  body false
                else
                  plan_result!(call, 204)
                end
              end

              { complete: ::TestManagement::Plans::CompleteService,
                reopen: ::TestManagement::Plans::ReopenService }.each do |action, service|
                namespace action do
                  post do
                    plan_result!(service.new(user: current_user, model: @plan).call, 200)
                  end
                end
              end

              namespace :rerun do
                post do
                  plan_result!(
                    ::TestManagement::Plans::RerunService.new(user: current_user, model: @plan, params: plan_request_body).call,
                    201
                  )
                end
              end

              namespace :entries do
                post do
                  authorize_in_project(%i[manage_test_plans], project: @plan.project)
                  call = ::TestManagement::Plans::Entries::CreateService
                           .new(user: current_user)
                           .call(plan_entry_attributes.merge(test_plan: @plan))
                  raise ::API::Errors::Unauthorized if call.errors.details[:base].pluck(:error).include?(:error_unauthorized)
                  raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

                  status 201
                  PlanRepresenter.new(@plan.reload, current_user:)
                end

                route_param :entry_id, type: Integer, desc: "Plan entry ID" do
                  patch do
                    entry = @plan.entries.find_by(id: params[:entry_id])
                    raise ::API::Errors::NotFound.new unless entry

                    call = ::TestManagement::Plans::Entries::UpdateService
                             .new(user: current_user, model: entry)
                             .call(plan_entry_attributes)
                    raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

                    PlanRepresenter.new(@plan.reload, current_user:)
                  end

                  delete do
                    entry = @plan.entries.find_by(id: params[:entry_id])
                    raise ::API::Errors::NotFound.new unless entry

                    call = ::TestManagement::Plans::Entries::DeleteService.new(user: current_user, model: entry).call
                    raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

                    status 204
                    body false
                  end
                end
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

              namespace :complete do
                post do
                  transition!(::TestManagement::TestRuns::CompleteService, @run,
                              completion_source: params[:completionSource] == "manual" ? "manual" : "automation")
                end
              end

              namespace :cancel do
                post do
                  transition!(::TestManagement::TestRuns::CancelService, @run,
                              completion_source: params[:completionSource] == "manual" ? "manual" : "automation")
                end
              end

              namespace :imports do
                get do
                  ImportCollectionRepresenter.new(@run.automation_imports.newest_first,
                                                  self_link: api_v3_paths.test_management_run_imports(@run.id),
                                                  current_user:)
                end
              end

              namespace :iterations do
                get do
                  iterations = ::TestManagement::TestRunIteration.preload_stats(@run.iterations.to_a, @run)
                  IterationCollectionRepresenter.new(iterations,
                                                     self_link: api_v3_paths.test_management_run_iterations(@run.id),
                                                     current_user:)
                end

                post do
                  name = params[:name] || params.dig(:iteration, :name)
                  call = ::TestManagement::TestRunIterations::StartService.new(user: current_user, run: @run).call(name:)
                  if call.failure?
                    symbols = call.errors.details[:base].pluck(:error)
                    raise ::API::Errors::Unauthorized if symbols.include?(:error_unauthorized)

                    raise ::API::Errors::Conflict.new(message: call.errors.full_messages.join(" "))
                  end
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

              resources :attachments do
                helpers ::API::V3::Attachments::AttachmentsByContainerAPI::Helpers

                helpers do
                  def container
                    @run
                  end

                  def get_attachment_self_path
                    api_v3_paths.test_management_run_attachments(container.id)
                  end
                end

                get &::API::V3::Attachments::AttachmentsByContainerAPI.read
                post &::API::V3::Attachments::AttachmentsByContainerAPI.create
              end
            end
          end

          namespace :run_cases do
            route_param :id, type: Integer, desc: "Test run case ID" do
              after_validation do
                @run_case = ::TestManagement::TestRunCase.includes(test_run: :project).find_by(id: params[:id])
                unless @run_case && allowed_any?(VIEW_PERMISSIONS, @run_case.project)
                  raise ::API::Errors::NotFound.new
                end
              end

              get do
                RunCaseRepresenter.new(@run_case, current_user:)
              end

              # 0020: { status?, comment?, errorMessage?, stepResults: [{ testStepId, status, actualResult? }] }.
              # 201 with the new result; 403 without execute_test_runs / add_test_runs; 409 for a
              # finished run; 422 for invalid statuses / steps or when nothing was given.
              post :results do
                body = request_body_hash
                steps = Array(body["stepResults"]).map do |entry|
                  entry = entry.respond_to?(:to_h) ? entry.to_h.stringify_keys : {}
                  { test_step_id: entry["testStepId"], status: entry["status"], actual_result: entry["actualResult"] }
                end
                attributes = { status: body["status"], comment: body["comment"], error_message: body["errorMessage"],
                               step_results: steps }.compact
                last_id = @run_case.results.maximum(:id).to_i
                call = ::TestManagement::RunCases::UpdateService.new(user: current_user, model: @run_case).call(attributes)
                symbols = call.errors.details[:base].pluck(:error)
                raise ::API::Errors::Unauthorized if symbols.include?(:error_unauthorized)
                raise ::API::Errors::Conflict.new(message: call.errors.full_messages.join(" ")) if symbols.include?(:tm_run_finished)
                raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

                result = @run_case.results.where("id > ?", last_id).order(:id).last
                raise ::API::Errors::UnprocessableContent.new(I18n.t("test_management.step_results.nothing_to_record")) unless result

                status 201
                ResultRepresenter.new(result, current_user:)
              end

              resources :attachments do
                helpers ::API::V3::Attachments::AttachmentsByContainerAPI::Helpers

                helpers do
                  def container
                    @run_case
                  end

                  def get_attachment_self_path
                    api_v3_paths.test_management_run_case_attachments(container.id)
                  end
                end

                get &::API::V3::Attachments::AttachmentsByContainerAPI.read
                post &::API::V3::Attachments::AttachmentsByContainerAPI.create
              end
            end
          end

          namespace :results do
            route_param :id, type: Integer, desc: "Test result ID" do
              get do
                result = ::TestManagement::TestResult.includes(:step_results, :user, :iteration, run_case: { test_run: :project })
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

              # 0016: 200 updated / 204 deleted; 403 without manage_test_ci, 404 not visible, 422 invalid.
              patch do
                connection = visible_ci_connection!(params[:id], CI_CONNECTION_PERMISSIONS)
                call = ::TestManagement::CiConnections::UpdateService
                         .new(user: current_user, model: connection)
                         .call(ci_connection_attributes)
                ci_connection_result!(call, 200)
              end

              delete do
                connection = visible_ci_connection!(params[:id], CI_CONNECTION_PERMISSIONS)
                call = ::TestManagement::CiConnections::DeleteService.new(user: current_user, model: connection).call
                if call.success?
                  status 204
                  body false
                else
                  ci_connection_result!(call, 204)
                end
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

# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Project-scoped automation endpoints (mounted in ProjectsAPI, :id):
      #   POST /api/v3/projects/:id/test_management/automation/results    ingest a report
      #   GET  /api/v3/projects/:id/test_management/runs                  runs (filters: externalRef, state, source)
      #   POST /api/v3/projects/:id/test_management/runs/:run_id/results  ingest into a given run
      #   GET  /api/v3/projects/:id/test_management/ci_connections        CI connections (no tokens)
      #   POST /api/v3/projects/:id/test_management/ci_connections        create (manage_test_ci, 0016)
      #   POST /api/v3/projects/:id/test_management/ci_triggers           "Run in CI" (0011)
      #   GET  /api/v3/projects/:id/test_management/milestones            milestones (filter: status, parentId)
      #   POST /api/v3/projects/:id/test_management/milestones            create (manage_test_milestones)
      #   POST /api/v3/projects/:id/test_management/assistant/generations  Test Assistant: generate drafts (0014)
      # Authentication: any APIv3 method, e.g. an API token (Authorization: Bearer …).
      class AutomationByProjectAPI < ::API::OpenProjectAPI
        UPLOAD_PERMISSIONS = %i[upload_test_results add_test_runs].freeze

        namespace :test_management do
          helpers IngestHelpers
          helpers MilestoneHelpers
          helpers PlanHelpers
          helpers AssistantHelpers
          helpers CiConnectionHelpers

          namespace :assistant do
            namespace :generations do
              # Queues a generation (202); poll GET /api/v3/test_management/assistant/generations/:id.
              post do
                assistant_allowed!(@project)
                call = ::TestManagement::AssistantGenerations::CreateService
                         .new(user: current_user)
                         .call(generation_params(assistant_body).merge(project: @project))
                assistant_failure!(call) if call.failure?

                status 202
                AssistantGenerationRepresenter.new(call.result, current_user:)
              end
            end
          end

          namespace :milestones do
            get do
              authorize_in_project(%i[view_test_runs], project: @project)
              milestones_enabled!(@project)
              milestones = @project.tm_milestones.includes(:parent, :version, :children).ordered
              statuses = params[:status].to_s.split(",") & ::TestManagement::Milestone::STATUSES
              milestones = milestones.where(status: statuses) if statuses.any?
              if params.key?(:parentId)
                milestones = milestones.where(parent_id: params[:parentId].presence)
              end
              MilestoneCollectionRepresenter.new(::TestManagement::Milestone.preload_summaries(milestones),
                                                 self_link: api_v3_paths.project_test_management_milestones(@project.id),
                                                 query: params.slice(:status, :parentId).to_h,
                                                 current_user:)
            end

            post do
              authorize_in_project(%i[manage_test_milestones], project: @project)
              milestones_enabled!(@project)
              call = ::TestManagement::Milestones::CreateService
                       .new(user: current_user)
                       .call(milestone_attributes.merge(project: @project))
              milestone_result!(call, 201)
            end
          end

          namespace :configuration_groups do
            get do
              authorize_in_project(%i[view_test_cases], project: @project)
              groups = @project.tm_configuration_groups.includes(:configurations).ordered
              elements = groups.map { ConfigurationGroupRepresenter.new(it, current_user:).to_hash }
              { _type: "Collection", total: elements.size, count: elements.size,
                _links: { self: { href: api_v3_paths.project_test_management_configuration_groups(@project.id) } },
                _embedded: { elements: } }
            end

            post do
              authorize_in_project(%i[manage_test_management], project: @project)
              body = (env["api.request.body"].presence || params).to_h.stringify_keys
              call = ::TestManagement::ConfigurationGroups::CreateService
                       .new(user: current_user)
                       .call(project: @project, name: body["name"])
              raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" ")) unless call.success?

              status 201
              ConfigurationGroupRepresenter.new(call.result, current_user:)
            end
          end

          namespace :plans do
            get do
              authorize_in_project(%i[view_test_plans], project: @project)
              plans_enabled!(@project)
              plans = @project.tm_test_plans.includes(:milestone, :assigned_to).newest_first
              states = params[:state].to_s.split(",") & ::TestManagement::TestPlan::STATES
              plans = plans.where(state: states) if states.any?
              plans = plans.where(milestone_id: params[:milestoneId]) if params[:milestoneId].present?
              PlanCollectionRepresenter.new(::TestManagement::TestPlan.preload_summaries(plans),
                                            self_link: api_v3_paths.project_test_management_plans(@project.id),
                                            current_user:)
            end

            post do
              authorize_in_project(%i[manage_test_plans], project: @project)
              plans_enabled!(@project)
              call = ::TestManagement::Plans::CreateService
                       .new(user: current_user)
                       .call(plan_attributes.merge(project: @project))
              plan_result!(call, 201)
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
              connections = ::TestManagement::CiConnection.where(project_id: @project.id).ordered
              CiConnectionCollectionRepresenter.new(connections.to_a,
                                                    self_link: api_v3_paths.project_test_management_ci_connections(@project.id),
                                                    current_user:)
            end

            # 0016: 201 created, 403 without manage_test_ci, 422 invalid.
            post do
              call = ::TestManagement::CiConnections::CreateService
                       .new(user: current_user)
                       .call(ci_connection_attributes.merge(project: @project))
              ci_connection_result!(call, 201)
            end
          end

          # "Run in CI": pre-create the run / iteration and trigger the CI job.
          # Body: connection (id or name, required), mode (new_run | new_iteration), one of
          # runId / suiteId / testCaseId, optional ref, name and milestone (id, "M12" or name;
          # new_run only, 0012). 201 triggered or, for an inbound-only connection (0015), prepared
          # (status "manual" + manualStart); 502 when the CI
          # provider refused (the run / iteration exist and carry the error), 422 invalid.
          namespace :ci_triggers do
            post do
              authorize_in_project(%i[trigger_test_automation], project: @project)
              find = lambda do |scope, key|
                next nil if params[key].blank?

                scope.find_by(id: params[key].to_s.to_i) || raise(::API::Errors::NotFound.new)
              end
              connection = ::TestManagement::CiConnection.lookup(@project, params[:connection].to_s)
              raise ::API::Errors::UnprocessableContent.new("Unknown CI connection.") unless connection

              call = ::TestManagement::CiTriggers::TriggerService.new(user: current_user).call(
                project: @project, connection:, mode: params[:mode].presence || "new_run",
                run: find.(@project.tm_test_runs, :runId),
                suite: find.(@project.tm_suites, :suiteId),
                test_case: find.(@project.tm_test_cases.not_deleted, :testCaseId),
                ref: params[:ref], name: params[:name],
                milestone: api_trigger_milestone(@project, params[:milestone])
              )
              if call.failure?
                raise ::API::Errors::Unauthorized if call.errors.details[:base].pluck(:error).include?(:error_unauthorized)

                raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" "))
              end

              status(call.result.triggered? || call.result.manual? ? 201 : 502)
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
              runs = runs.where(milestone_id: params[:milestoneId]) if params[:milestoneId].present?
              runs = runs.where("LOWER(tm_test_runs.name) = ?", params[:name].to_s.downcase) if params[:name].present?
              RunCollectionRepresenter.new(::TestManagement::TestRun.preload_stats(runs.limit(500)),
                                           self_link: api_v3_paths.project_test_management_runs(@project.id),
                                           query: params.slice(:externalRef, :state, :source, :name, :milestoneId).to_h,
                                           current_user:)
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

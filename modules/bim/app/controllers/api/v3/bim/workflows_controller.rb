# frozen_string_literal: true

module API
  module V3
    module Bim
      class WorkflowsController < BaseController
        before_action :authorize_admin, only: [:create_template, :update_template, :destroy_template]
        before_action :find_workflow_template, only: [:show_template, :update_template, :destroy_template]
        before_action :find_workflowable, only: [:execute_transition, :available_transitions, :workflow_state, :workflow_timeline]

        # GET /api/v3/bim/workflows/templates
        # List all workflow templates
        def index_templates
          templates = ::Bim::WorkflowTemplate.active

          # Filter by project if specified
          if params[:project_id]
            templates = templates.for_project(params[:project_id])
          end

          # Filter by type if specified
          if params[:workflow_type]
            templates = templates.for_type(params[:workflow_type])
          end

          templates = templates.includes(:project, :created_by)

          render json: {
            _type: 'Collection',
            count: templates.count,
            total: templates.count,
            _embedded: {
              elements: templates.map { |t| format_template(t) }
            }
          }
        end

        # GET /api/v3/bim/workflows/templates/:id
        # Get workflow template details
        def show_template
          render json: format_template(@template, include_details: true)
        end

        # POST /api/v3/bim/workflows/templates
        # Create a new workflow template
        def create_template
          template_params = params.require(:workflow_template).permit(
            :name, :description, :workflow_type, :project_id, :is_default, :active,
            states: [:name, :label, :color, :initial, :final, :description],
            transitions: [:name, :from, :to, :label, :guard, :required_role, actions: []],
            configuration: {}
          )

          template = ::Bim::WorkflowTemplate.new(template_params)
          template.created_by = current_user

          if template.save
            render json: format_template(template, include_details: true), status: :created
          else
            render json: {
              _type: 'Error',
              errorIdentifier: 'validation_failed',
              message: template.errors.full_messages.join(', ')
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v3/bim/workflows/templates/:id
        # Update workflow template
        def update_template
          template_params = params.require(:workflow_template).permit(
            :name, :description, :is_default, :active,
            states: [:name, :label, :color, :initial, :final, :description],
            transitions: [:name, :from, :to, :label, :guard, :required_role, actions: []],
            configuration: {}
          )

          @template.updated_by = current_user

          if @template.update(template_params)
            render json: format_template(@template, include_details: true)
          else
            render json: {
              _type: 'Error',
              errorIdentifier: 'validation_failed',
              message: @template.errors.full_messages.join(', ')
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/workflows/templates/:id
        # Delete workflow template
        def destroy_template
          if @template.destroy
            render json: { _type: 'Success', message: 'Workflow template deleted successfully' }
          else
            render json: {
              _type: 'Error',
              errorIdentifier: 'deletion_failed',
              message: @template.errors.full_messages.join(', ')
            }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/workflows/:workflowable_type/:workflowable_id/transition
        # Execute a workflow transition
        def execute_transition
          transition_name = params.require(:transition)
          comment = params[:comment]
          metadata = params[:metadata] || {}

          begin
            @workflowable.transition_to!(
              transition_name,
              user: current_user,
              comment: comment,
              metadata: metadata,
              request: request
            )

            render json: {
              _type: 'WorkflowTransition',
              success: true,
              message: "Transition '#{transition_name}' executed successfully",
              workflow_state: @workflowable.workflow_state,
              workflow_state_label: @workflowable.workflow_state_label,
              workflowable: format_workflowable(@workflowable)
            }
          rescue ::Bim::Services::WorkflowEngine::InvalidTransitionError => e
            render json: {
              _type: 'Error',
              errorIdentifier: 'invalid_transition',
              message: e.message
            }, status: :unprocessable_entity
          rescue ::Bim::Services::WorkflowEngine::GuardFailedError => e
            render json: {
              _type: 'Error',
              errorIdentifier: 'guard_failed',
              message: e.message
            }, status: :forbidden
          rescue ::Bim::Services::WorkflowEngine::PermissionError => e
            render json: {
              _type: 'Error',
              errorIdentifier: 'permission_denied',
              message: e.message
            }, status: :forbidden
          end
        end

        # GET /api/v3/bim/workflows/:workflowable_type/:workflowable_id/available_transitions
        # Get available transitions for current state
        def available_transitions
          transitions = @workflowable.available_transitions(user: current_user)

          render json: {
            _type: 'Collection',
            count: transitions.count,
            workflow_state: @workflowable.workflow_state,
            workflow_state_label: @workflowable.workflow_state_label,
            _embedded: {
              elements: transitions.map do |transition|
                {
                  name: transition['name'],
                  label: transition['label'] || transition['name'].humanize,
                  from: transition['from'],
                  to: transition['to'],
                  to_label: @workflowable.workflow_template.state_label(transition['to']),
                  required_role: transition['required_role'],
                  actions: transition['actions'] || []
                }
              end
            }
          }
        end

        # GET /api/v3/bim/workflows/:workflowable_type/:workflowable_id/state
        # Get current workflow state
        def workflow_state
          render json: {
            _type: 'WorkflowState',
            workflow_state: @workflowable.workflow_state,
            workflow_state_label: @workflowable.workflow_state_label,
            workflow_state_color: @workflowable.workflow_state_color,
            is_initial_state: @workflowable.in_initial_state?,
            is_final_state: @workflowable.in_final_state?,
            time_in_state: @workflowable.time_in_current_state&.to_i,
            time_in_state_label: @workflowable.time_in_current_state_label,
            workflow_template: @workflowable.workflow_template ? format_template(@workflowable.workflow_template) : nil,
            workflowable: format_workflowable(@workflowable)
          }
        end

        # GET /api/v3/bim/workflows/:workflowable_type/:workflowable_id/timeline
        # Get workflow transition history
        def workflow_timeline
          timeline = @workflowable.workflow_timeline
          statistics = @workflowable.workflow_statistics

          render json: {
            _type: 'WorkflowTimeline',
            workflowable: format_workflowable(@workflowable),
            statistics: statistics,
            _embedded: {
              timeline: timeline
            }
          }
        end

        # GET /api/v3/bim/workflows/logs
        # Get workflow logs (with filters)
        def logs
          logs = ::Bim::WorkflowLog.all

          # Filter by workflowable type
          if params[:workflowable_type]
            logs = logs.where(workflowable_type: params[:workflowable_type])
          end

          # Filter by user
          if params[:user_id]
            logs = logs.by_user(params[:user_id])
          end

          # Filter by date range
          if params[:since]
            logs = logs.where('created_at >= ?', params[:since])
          end

          logs = logs.reverse_chronological.includes(:user, :workflow_template, :workflowable).limit(100)

          render json: {
            _type: 'Collection',
            count: logs.count,
            _embedded: {
              elements: logs.map { |log| format_log(log) }
            }
          }
        end

        private

        def find_workflow_template
          @template = ::Bim::WorkflowTemplate.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            _type: 'Error',
            errorIdentifier: 'not_found',
            message: 'Workflow template not found'
          }, status: :not_found
        end

        def find_workflowable
          workflowable_type = params[:workflowable_type]
          workflowable_id = params[:workflowable_id]

          klass = case workflowable_type
                  when 'issue', 'issues'
                    ::Bim::Bcf::Issue
                  when 'clash', 'clashes'
                    ::Bim::Clash
                  when 'element_link', 'element_links'
                    ::Bim::ElementLink
                  else
                    raise ArgumentError, "Unknown workflowable type: #{workflowable_type}"
                  end

          @workflowable = klass.find(workflowable_id)
        rescue ActiveRecord::RecordNotFound
          render json: {
            _type: 'Error',
            errorIdentifier: 'not_found',
            message: "#{workflowable_type} not found"
          }, status: :not_found
        rescue ArgumentError => e
          render json: {
            _type: 'Error',
            errorIdentifier: 'invalid_type',
            message: e.message
          }, status: :bad_request
        end

        def authorize_admin
          unless current_user.admin?
            render json: {
              _type: 'Error',
              errorIdentifier: 'unauthorized',
              message: 'Admin access required'
            }, status: :forbidden
          end
        end

        def format_template(template, include_details: false)
          base = {
            _type: 'WorkflowTemplate',
            id: template.id,
            name: template.name,
            description: template.description,
            workflow_type: template.workflow_type,
            is_default: template.is_default,
            active: template.active,
            project_id: template.project_id,
            created_at: template.created_at,
            updated_at: template.updated_at
          }

          if include_details
            base.merge!(
              states: template.states,
              transitions: template.transitions,
              configuration: template.configuration,
              state_machine_diagram: template.state_machine_diagram,
              _links: {
                self: { href: api_v3_paths.bim_workflow_template(template.id) },
                project: template.project ? { href: api_v3_paths.project(template.project.id) } : nil
              }
            )
          end

          base
        end

        def format_workflowable(workflowable)
          {
            _type: workflowable.class.name.demodulize,
            id: workflowable.id,
            workflow_state: workflowable.workflow_state,
            workflow_state_label: workflowable.workflow_state_label
          }
        end

        def format_log(log)
          {
            _type: 'WorkflowLog',
            id: log.id,
            transition_label: log.transition_label,
            from_state: log.from_state,
            to_state: log.to_state,
            transition_name: log.transition_name,
            user: {
              id: log.user.id,
              name: log.user.name
            },
            comment: log.comment,
            metadata: log.metadata,
            duration_in_state: log.duration_in_state,
            duration_label: log.duration_label,
            automated: log.automated,
            created_at: log.created_at,
            workflowable: {
              type: log.workflowable_type,
              id: log.workflowable_id
            }
          }
        end
      end
    end
  end
end

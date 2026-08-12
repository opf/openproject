# frozen_string_literal: true

module API
  module V3
    module Cde
      class ContainersController < API::BaseController
        include API::Helper::Authorization

        before_action :find_container, only: %i[show update destroy share publish archive]
        before_action :check_container_permission, only: %i[show update destroy]
        before_action :check_manage_permission, only: %i[share publish archive]

        # GET /api/v3/cde/containers
        def index
          containers = Cde::Container.includes(:project, :owner, :revisions)
          containers = containers.where(project_id: params[:project_id]) if params[:project_id].present?
          containers = containers.where(status: params[:status]) if params[:status].present?
          containers = containers.search(params[:query]) if params[:query].present?

          render_api_json(containers)
        end

        # GET /api/v3/cde/containers/:id
        def show
          render_api_json(@container, root: 'container')
        end

        # POST /api/v3/cde/containers
        def create
          container = Cde::Container.new(container_params)
          container.project = Project.find(params[:project_id])
          container.owner = current_api_user

          if container.save
            render_api_json(container, root: 'container', status: :created)
          else
            render_api_error(container.errors, status: :unprocessable_entity)
          end
        end

        # PUT /api/v3/cde/containers/:id
        def update
          if @container.update(container_params)
            render_api_json(@container, root: 'container')
          else
            render_api_error(@container.errors, status: :unprocessable_entity)
          end
        end

        # DELETE /api/v3/cde/containers/:id
        def destroy
          @container.destroy
          head :no_content
        end

        # POST /api/v3/cde/containers/:id/share
        def share
          @container.share!(user: current_api_user)
          render_api_json(@container, root: 'container')
        end

        # POST /api/v3/cde/containers/:id/publish
        def publish
          begin
            Cde::PublicationGate.enforce(@container, user: current_api_user)
            @container.publish!(user: current_api_user)
            render_api_json(@container, root: 'container')
          rescue Cde::PublicationGate::PublicationError => e
            render_api_error({ publication_gate: e.message }, status: :precondition_failed)
          end
        end

        # POST /api/v3/cde/containers/:id/archive
        def archive
          @container.archive!(user: current_api_user)
          render_api_json(@container, root: 'container')
        end

        private

        def find_container
          @container = Cde::Container.find_by!(id: params[:id])
        rescue ActiveRecord::RecordNotFound
          render_api_error({ error: 'Container not found' }, status: :not_found)
        end

        def check_container_permission
          raise CanCan::AccessDenied unless current_api_user.allowed_to?(:view_wip_container, @container.project)
        end

        def check_manage_permission
          raise CanCan::AccessDenied unless current_api_user.allowed_to?(:edit_container, @container.project)
        end

        def container_params
          params.require(:container).permit(:identifier, :title, :description, :original_filename)
        end
      end
    end
  end
end

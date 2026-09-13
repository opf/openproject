# frozen_string_literal: true

module API
  module V3
    module Bim
      class FederationsController < ApplicationController
        before_action :find_project
        before_action :find_federation, only: %i[show update destroy align viewer_config]
        before_action :authorize

        def index
          federations = @project.model_federations.includes(:ifc_models).ordered

          render json: {
            _type: 'Collection',
            total: federations.count,
            count: federations.size,
            _embedded: {
              elements: federations.map { |f| federation_representer(f) }
            }
          }
        end

        def show
          render json: federation_representer(@federation)
        end

        def create
          service = ::Bim::Federations::CreateService.new(user: current_user, project: @project)
          result = service.call(params: permitted_params)

          if result.success?
            render json: federation_representer(result.result), status: :created
          else
            render json: { error: result.errors }, status: :unprocessable_entity
          end
        end

        def update
          if @federation.update(update_params)
            render json: federation_representer(@federation)
          else
            render json: { errors: @federation.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          if @federation.destroy
            head :no_content
          else
            render json: { errors: @federation.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/projects/:project_id/bim/federations/:id/align
        def align
          alignment_service = ::Bim::Federations::AlignmentService.new(@federation)
          result = alignment_service.call

          if result.success?
            render json: {
              message: 'Models aligned successfully',
              transformations: result.result
            }
          else
            render json: { error: result.errors }, status: :unprocessable_entity
          end
        end

        # GET /api/v3/projects/:project_id/bim/federations/:id/viewer_config
        def viewer_config
          config = @federation.viewer_config

          render json: {
            _type: 'FederationViewerConfig',
            federation_id: config[:federation_id],
            name: config[:name],
            base_point: config[:base_point],
            rotation: config[:rotation],
            units: config[:units],
            models: config[:models]
          }
        end

        private

        def find_project
          @project = Project.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Project not found' }, status: :not_found
        end

        def find_federation
          @federation = @project.model_federations.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Federation not found' }, status: :not_found
        end

        def authorize
          # Check if user has permission to manage BIM models
          unless current_user.allowed_in_project?(:manage_ifc_models, @project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def permitted_params
          params.permit(
            :name,
            :description,
            :units,
            :auto_align,
            base_point: [:x, :y, :z],
            rotation: [:x, :y, :z],
            model_ids: []
          ).to_h
        end

        def update_params
          params.permit(
            :name,
            :description,
            :units,
            base_point: [:x, :y, :z],
            rotation: [:x, :y, :z]
          )
        end

        def federation_representer(federation)
          {
            _type: 'ModelFederation',
            id: federation.id,
            name: federation.name,
            description: federation.description,
            base_point: federation.base_point,
            rotation: federation.rotation,
            units: federation.units,
            created_at: federation.created_at.iso8601,
            updated_at: federation.updated_at.iso8601,
            _embedded: {
              models: federation.federation_models.ordered_by_display.map { |fm| federation_model_representer(fm) }
            },
            statistics: federation.statistics,
            _links: {
              self: { href: api_v3_paths.project_bim_federation(federation.project_id, federation.id) },
              project: { href: api_v3_paths.project(federation.project_id) },
              align: { href: align_api_v3_project_bim_federation_path(federation.project_id, federation.id) },
              viewer_config: { href: viewer_config_api_v3_project_bim_federation_path(federation.project_id, federation.id) }
            }
          }
        end

        def federation_model_representer(federation_model)
          {
            id: federation_model.id,
            discipline: federation_model.discipline,
            discipline_name: federation_model.discipline_name,
            transform: federation_model.transform,
            visible: federation_model.visible,
            color: federation_model.color,
            opacity: federation_model.opacity,
            display_order: federation_model.display_order,
            ifc_model: {
              id: federation_model.ifc_model.id,
              title: federation_model.ifc_model.title
            }
          }
        end
      end
    end
  end
end

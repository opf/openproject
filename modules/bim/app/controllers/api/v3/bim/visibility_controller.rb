# frozen_string_literal: true

module API
  module V3
    module Bim
      class VisibilityController < ApplicationController
        before_action :find_ifc_model
        before_action :authorize_view_access

        # GET /api/v3/bim/ifc_models/:id/visibility
        # Get current visibility state
        def show
          service = ::Bim::Services::VisibilityService.new(@ifc_model)
          state = service.current_state
          stats = service.statistics

          render json: {
            _type: 'BimVisibilityState',
            model_id: @ifc_model.id,
            state: {
              filters: state[:filters],
              overrides_count: state[:overrides]&.size || 0,
              isolation: state[:isolation],
              updated_at: state[:updated_at]
            },
            statistics: stats,
            _links: {
              self: { href: api_v3_bim_ifc_model_visibility_path(@ifc_model.id) },
              apply: { href: api_v3_bim_ifc_model_visibility_path(@ifc_model.id) },
              isolate: { href: api_v3_bim_ifc_model_visibility_isolate_path(@ifc_model.id) },
              reset: { href: api_v3_bim_ifc_model_visibility_reset_path(@ifc_model.id) }
            }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/visibility
        # Apply visibility filters
        def apply
          filters = parse_filters(params[:filters] || {})
          overrides = params[:overrides] || {}

          service = ::Bim::Services::VisibilityService.new(@ifc_model)
          result = service.apply_filters(
            filters: filters,
            overrides: overrides.to_unsafe_h,
            user: current_user
          )

          if result[:success]
            render json: {
              _type: 'BimVisibilityApply',
              success: true,
              model_id: @ifc_model.id,
              visible_count: result[:visible_count],
              hidden_count: result[:hidden_count],
              filters: filters,
              _links: {
                self: { href: api_v3_bim_ifc_model_visibility_path(@ifc_model.id) },
                state: { href: api_v3_bim_ifc_model_visibility_path(@ifc_model.id) }
              }
            }
          else
            render json: { error: result[:errors] }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/ifc_models/:id/visibility/isolate
        # Isolate specific elements (hide all others)
        def isolate
          element_guids = params[:element_guids] || []

          if element_guids.empty?
            return render json: { error: 'Element GUIDs required' }, status: :bad_request
          end

          service = ::Bim::Services::VisibilityService.new(@ifc_model)
          result = service.isolate_elements(
            element_guids: element_guids,
            user: current_user
          )

          if result[:success]
            render json: {
              _type: 'BimVisibilityIsolate',
              success: true,
              model_id: @ifc_model.id,
              isolated_count: result[:isolated_count],
              hidden_count: result[:hidden_count],
              element_guids: element_guids,
              _links: {
                self: { href: api_v3_bim_ifc_model_visibility_isolate_path(@ifc_model.id) },
                exit_isolation: { href: api_v3_bim_ifc_model_visibility_reset_path(@ifc_model.id) }
              }
            }
          else
            render json: { error: result[:error] }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/ifc_models/:id/visibility/reset
        # Reset visibility to default (show all)
        def reset
          service = ::Bim::Services::VisibilityService.new(@ifc_model)
          result = service.reset(user: current_user)

          render json: {
            _type: 'BimVisibilityReset',
            success: true,
            model_id: @ifc_model.id,
            visible_count: result[:visible_count],
            message: 'Visibility reset to default',
            _links: {
              self: { href: api_v3_bim_ifc_model_visibility_reset_path(@ifc_model.id) },
              state: { href: api_v3_bim_ifc_model_visibility_path(@ifc_model.id) }
            }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/visibility/toggle
        # Toggle visibility for specific elements
        def toggle
          element_guids = params[:element_guids] || []
          visible = params[:visible]

          if element_guids.empty?
            return render json: { error: 'Element GUIDs required' }, status: :bad_request
          end

          if visible.nil?
            return render json: { error: 'Visible parameter required (true/false)' }, status: :bad_request
          end

          service = ::Bim::Services::VisibilityService.new(@ifc_model)
          result = service.toggle_elements(
            element_guids: element_guids,
            visible: visible,
            user: current_user
          )

          if result[:success]
            render json: {
              _type: 'BimVisibilityToggle',
              success: true,
              model_id: @ifc_model.id,
              toggled_count: result[:toggled_count],
              visible: visible,
              _links: {
                self: { href: api_v3_bim_ifc_model_visibility_path(@ifc_model.id) }
              }
            }
          else
            render json: { error: result[:error] }, status: :unprocessable_entity
          end
        end

        private

        def find_ifc_model
          @ifc_model = ::Bim::IfcModel::IfcModel.find(params[:id] || params[:ifc_model_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC Model not found' }, status: :not_found
        end

        def authorize_view_access
          unless current_user.allowed_in_project?(:view_ifc_models, @ifc_model.project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def parse_filters(filters_param)
          filters = {}
          filters[:types] = filters_param[:types] if filters_param[:types].present?
          filters[:disciplines] = filters_param[:disciplines] if filters_param[:disciplines].present?
          filters[:levels] = filters_param[:levels] if filters_param[:levels].present?
          filters[:statuses] = filters_param[:statuses] if filters_param[:statuses].present?

          if filters_param[:custom].present?
            filters[:custom] = {
              property: filters_param[:custom][:property],
              operator: filters_param[:custom][:operator],
              value: filters_param[:custom][:value]
            }
          end

          filters
        end
      end
    end
  end
end

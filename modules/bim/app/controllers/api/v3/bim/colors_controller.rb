# frozen_string_literal: true

module API
  module V3
    module Bim
      class ColorsController < ApplicationController
        before_action :find_ifc_model
        before_action :authorize_view_access

        # GET /api/v3/bim/ifc_models/:id/colors/schemes
        # Get available color schemes
        def schemes
          service = ::Bim::Services::ColorSchemeService.new(@ifc_model)
          available = service.available_schemes
          current = service.current_state

          render json: {
            _type: 'BimColorSchemes',
            model_id: @ifc_model.id,
            schemes: available[:schemes],
            custom_schemes: available[:custom_schemes],
            current_scheme: current[:scheme],
            current_colors: current[:colors],
            _links: {
              self: { href: api_v3_bim_ifc_model_colors_schemes_path(@ifc_model.id) },
              apply: { href: api_v3_bim_ifc_model_colors_path(@ifc_model.id) },
              reset: { href: api_v3_bim_ifc_model_colors_reset_path(@ifc_model.id) }
            }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/colors
        # Apply color scheme
        def apply
          scheme_name = params[:scheme]
          custom_colors = params[:custom_colors] || {}

          if scheme_name.blank?
            return render json: { error: 'Scheme name required' }, status: :bad_request
          end

          service = ::Bim::Services::ColorSchemeService.new(@ifc_model)
          result = service.apply_scheme(
            scheme_name: scheme_name,
            custom_colors: custom_colors.to_unsafe_h,
            user: current_user
          )

          if result[:success]
            render json: {
              _type: 'BimColorSchemeApply',
              success: true,
              model_id: @ifc_model.id,
              scheme: result[:scheme],
              elements_colored: result[:elements_colored],
              _links: {
                self: { href: api_v3_bim_ifc_model_colors_path(@ifc_model.id) },
                schemes: { href: api_v3_bim_ifc_model_colors_schemes_path(@ifc_model.id) }
              }
            }
          else
            render json: { error: result[:error] }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/ifc_models/:id/colors/by_property
        # Apply color by property value
        def by_property
          property_name = params[:property_name]
          color_mapping = params[:color_mapping] || {}
          default_color = params[:default_color]

          if property_name.blank?
            return render json: { error: 'Property name required' }, status: :bad_request
          end

          if color_mapping.empty?
            return render json: { error: 'Color mapping required' }, status: :bad_request
          end

          service = ::Bim::Services::ColorSchemeService.new(@ifc_model)
          result = service.apply_by_property(
            property_name: property_name,
            color_mapping: color_mapping.to_unsafe_h,
            default_color: default_color,
            user: current_user
          )

          if result[:success]
            render json: {
              _type: 'BimColorByProperty',
              success: true,
              model_id: @ifc_model.id,
              property: result[:property],
              elements_colored: result[:elements_colored],
              _links: {
                self: { href: api_v3_bim_ifc_model_colors_by_property_path(@ifc_model.id) },
                reset: { href: api_v3_bim_ifc_model_colors_reset_path(@ifc_model.id) }
              }
            }
          else
            render json: { error: result[:error] }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/ifc_models/:id/colors/reset
        # Reset colors to original
        def reset
          service = ::Bim::Services::ColorSchemeService.new(@ifc_model)
          result = service.reset(user: current_user)

          render json: {
            _type: 'BimColorsReset',
            success: true,
            model_id: @ifc_model.id,
            message: result[:message],
            _links: {
              self: { href: api_v3_bim_ifc_model_colors_reset_path(@ifc_model.id) },
              schemes: { href: api_v3_bim_ifc_model_colors_schemes_path(@ifc_model.id) }
            }
          }
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
      end
    end
  end
end

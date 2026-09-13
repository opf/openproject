# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Api
  module V3
    module Bim
      class ComparisonsController < ApplicationController
        before_action :find_comparison, only: [:show, :update, :destroy, :approve, :reject]
        before_action :authorize_view, only: [:index, :show]
        before_action :authorize_manage, only: [:create, :update, :destroy, :approve, :reject]

        ##
        # List model comparisons
        #
        # GET /api/v3/bim/comparisons
        #
        # Query parameters:
        # - model_id: Filter by model (comparisons involving this model)
        # - status: Filter by status (pending, completed, approved, rejected)
        # - comparison_type: Filter by type (version, baseline, federated)
        # - page: Page number (default: 1)
        # - per_page: Items per page (default: 20, max: 100)
        #
        def index
          comparisons = ::Bim::ModelComparison.all

          # Apply filters
          comparisons = comparisons.for_model(model) if params[:model_id].present? && model
          comparisons = comparisons.where(status: params[:status]) if params[:status].present?
          comparisons = comparisons.where(comparison_type: params[:comparison_type]) if params[:comparison_type].present?
          comparisons = comparisons.where(created_by: params[:created_by_id]) if params[:created_by_id].present?

          # Pagination
          page = [params[:page].to_i, 1].max
          per_page = [[params[:per_page].to_i, 1].max, 100].min
          per_page = 20 if per_page.zero?

          total = comparisons.count
          comparisons = comparisons.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)

          render json: {
            comparisons: comparisons.map { |c| serialize_comparison(c) },
            total: total,
            page: page,
            per_page: per_page
          }
        end

        ##
        # Show comparison details
        #
        # GET /api/v3/bim/comparisons/:id
        #
        def show
          render json: serialize_comparison(@comparison, include_details: true)
        end

        ##
        # Create and run model comparison
        #
        # POST /api/v3/bim/comparisons
        #
        # Request body:
        # {
        #   "model1_id": 123,
        #   "model2_id": 456,
        #   "name": "V1 vs V2",
        #   "comparison_type": "version",
        #   "options": {
        #     "detect_geometry_changes": true,
        #     "detect_property_changes": true
        #   }
        # }
        #
        def create
          model1 = find_model(params[:model1_id])
          model2 = find_model(params[:model2_id])

          return render_error('model1_id is required', :bad_request) unless model1
          return render_error('model2_id is required', :bad_request) unless model2

          service = ::Bim::Comparison::CompareService.new(
            model1: model1,
            model2: model2,
            options: comparison_options.merge(user: current_user)
          )

          result = service.call

          if result.success?
            comparison = result.result

            # Update name and description if provided
            comparison.update(
              name: params[:name],
              description: params[:description]
            ) if params[:name].present? || params[:description].present?

            render json: serialize_comparison(comparison, include_details: true), status: :created
          else
            render_error(result.errors.join(', '), :unprocessable_entity)
          end
        end

        ##
        # Update comparison
        #
        # PATCH /api/v3/bim/comparisons/:id
        #
        # Request body:
        # {
        #   "name": "Updated name",
        #   "description": "Updated description",
        #   "status": "completed"
        # }
        #
        def update
          permitted_params = params.permit(:name, :description, :status, :status_comment)

          if @comparison.update(permitted_params)
            render json: serialize_comparison(@comparison)
          else
            render_error(@comparison.errors.full_messages.join(', '), :unprocessable_entity)
          end
        end

        ##
        # Delete comparison
        #
        # DELETE /api/v3/bim/comparisons/:id
        #
        def destroy
          @comparison.destroy
          head :no_content
        end

        ##
        # Approve comparison
        #
        # POST /api/v3/bim/comparisons/:id/approve
        #
        # Request body:
        # {
        #   "comment": "Changes approved for implementation"
        # }
        #
        def approve
          return render_error('comment is required', :bad_request) unless params[:comment].present?

          if @comparison.approve!(user: current_user, comment: params[:comment])
            render json: serialize_comparison(@comparison)
          else
            render_error(@comparison.errors.full_messages.join(', '), :unprocessable_entity)
          end
        end

        ##
        # Reject comparison
        #
        # POST /api/v3/bim/comparisons/:id/reject
        #
        # Request body:
        # {
        #   "comment": "Changes not acceptable - too many structural modifications"
        # }
        #
        def reject
          return render_error('comment is required', :bad_request) unless params[:comment].present?

          if @comparison.reject!(user: current_user, comment: params[:comment])
            render json: serialize_comparison(@comparison)
          else
            render_error(@comparison.errors.full_messages.join(', '), :unprocessable_entity)
          end
        end

        private

        def find_comparison
          @comparison = ::Bim::ModelComparison.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error('Comparison not found', :not_found)
        end

        def find_model(model_id)
          return nil unless model_id.present?

          ::Bim::IfcModels::IfcModel.find_by(id: model_id)
        end

        def model
          @model ||= find_model(params[:model_id])
        end

        def comparison_options
          options = params[:options] || {}

          {
            detect_geometry_changes: options[:detect_geometry_changes] != false,
            detect_property_changes: options[:detect_property_changes] != false,
            detect_type_changes: options[:detect_type_changes] != false,
            ignore_properties: options[:ignore_properties] || [],
            comparison_type: params[:comparison_type] || :version
          }
        end

        def serialize_comparison(comparison, include_details: false)
          data = {
            id: comparison.id,
            model1_id: comparison.model1_id,
            model2_id: comparison.model2_id,
            model1_title: comparison.model1.title,
            model2_title: comparison.model2.title,
            name: comparison.name,
            description: comparison.description,
            comparison_type: comparison.comparison_type,
            status: comparison.status,
            added_count: comparison.added_count,
            deleted_count: comparison.deleted_count,
            modified_count: comparison.modified_count,
            unchanged_count: comparison.unchanged_count,
            total_changes: comparison.total_changes,
            total_elements: comparison.total_elements,
            change_percentage: comparison.change_percentage,
            comparison_time: comparison.comparison_time,
            created_at: comparison.created_at,
            completed_at: comparison.completed_at,
            created_by_id: comparison.created_by_id,
            approved_by_id: comparison.approved_by_id,
            approved_at: comparison.approved_at,
            status_comment: comparison.status_comment
          }

          if include_details
            data.merge!(
              changes_data: comparison.changes_data,
              statistics: comparison.statistics,
              change_summary: comparison.change_summary,
              changes_by_type: comparison.changes_by_type
            )
          end

          data
        end

        def authorize_view
          # Check if user has permission to view IFC models
          return if User.current.allowed_globally?(:view_ifc_models)

          render_error('Unauthorized', :forbidden)
        end

        def authorize_manage
          # Check if user has permission to manage IFC models
          return if User.current.allowed_globally?(:manage_ifc_models)

          render_error('Unauthorized', :forbidden)
        end

        def render_error(message, status)
          render json: { message: message }, status: status
        end
      end
    end
  end
end

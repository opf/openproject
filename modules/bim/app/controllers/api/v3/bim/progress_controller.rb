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

module API
  module V3
    module Bim
      ##
      # API Controller for Element Progress
      #
      # Endpoints:
      #   GET    /api/v3/bim/progress       - List element progress
      #   GET    /api/v3/bim/progress/:id   - Show element progress
      #   POST   /api/v3/bim/progress       - Create/update element progress
      #   PATCH  /api/v3/bim/progress/:id   - Update element progress
      #   DELETE /api/v3/bim/progress/:id   - Delete element progress
      #   POST   /api/v3/bim/progress/bulk_update - Bulk update progress
      #   POST   /api/v3/bim/progress/sync_work_packages - Sync from work packages
      #   GET    /api/v3/bim/progress/statistics - Get model statistics
      #
      class ProgressController < ApplicationController
        before_action :find_progress, only: %i[show update destroy]
        before_action :authorize_view, only: %i[index show statistics]
        before_action :authorize_manage, only: %i[create update destroy bulk_update sync_work_packages]

        ##
        # List element progress with filtering
        #
        # Query parameters:
        #   - model_id: Filter by IFC model (required)
        #   - status: Filter by status (planned, in_progress, completed, on_hold)
        #   - element_type: Filter by element type
        #   - work_package_id: Filter by work package
        #   - baseline_id: Filter by baseline (nil = current)
        #   - page: Page number (default: 1)
        #   - per_page: Results per page (default: 50, max: 200)
        #
        def index
          unless params[:model_id]
            return render json: { error: 'model_id parameter required' }, status: :bad_request
          end

          progresses = ::Bim::ElementProgress.for_model(params[:model_id])

          # Filtering
          progresses = progresses.where(status: params[:status]) if params[:status]
          progresses = progresses.by_type(params[:element_type]) if params[:element_type]
          progresses = progresses.by_work_package(params[:work_package_id]) if params[:work_package_id]

          if params[:baseline_id]
            progresses = progresses.for_baseline(params[:baseline_id])
          else
            progresses = progresses.current
          end

          # Pagination
          page = params[:page]&.to_i || 1
          per_page = [params[:per_page]&.to_i || 50, 200].min

          progresses = progresses.page(page).per(per_page)

          render json: {
            progress: progresses.map { |p| serialize_progress(p) },
            total: progresses.total_count,
            page: page,
            per_page: per_page
          }
        end

        ##
        # Show single element progress
        #
        def show
          render json: serialize_progress(@progress, detailed: true)
        end

        ##
        # Create or update element progress
        #
        # Parameters:
        #   - ifc_model_id: IFC model ID (required)
        #   - element_id: Element ID (required)
        #   - percent_complete: Progress percentage (0-100)
        #   - status: Status override
        #   - planned_start, planned_finish, actual_start, actual_finish: Dates
        #   - work_package_id: Link to work package
        #
        def create
          unless params[:ifc_model_id] && params[:element_id]
            return render json: { error: 'ifc_model_id and element_id required' }, status: :bad_request
          end

          model = ::Bim::IfcModels::IfcModel.find(params[:ifc_model_id])
          service = ::Bim::Progress::TrackingService.new(ifc_model: model, user: current_user)

          result = service.update_element_progress(
            element_id: params[:element_id],
            percent_complete: params[:percent_complete] || 0,
            status: params[:status]&.to_sym,
            planned_start: params[:planned_start],
            planned_finish: params[:planned_finish],
            work_package_id: params[:work_package_id]
          )

          if result.success?
            render json: serialize_progress(result.result, detailed: true), status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC model not found' }, status: :not_found
        end

        ##
        # Update element progress
        #
        def update
          attrs = progress_params.to_h

          if attrs[:percent_complete]
            # Use service for progress updates to ensure proper status transitions
            service = ::Bim::Progress::TrackingService.new(ifc_model: @progress.ifc_model, user: current_user)
            result = service.update_element_progress(
              element_id: @progress.element_id,
              **attrs.symbolize_keys
            )

            if result.success?
              render json: serialize_progress(result.result, detailed: true)
            else
              render json: { errors: result.errors }, status: :unprocessable_entity
            end
          elsif @progress.update(attrs)
            render json: serialize_progress(@progress, detailed: true)
          else
            render json: { errors: @progress.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Delete element progress
        #
        def destroy
          @progress.destroy
          head :no_content
        end

        ##
        # Bulk update progress for multiple elements
        #
        # POST /api/v3/bim/progress/bulk_update
        #
        # Body:
        #   {
        #     "model_id": 123,
        #     "updates": [
        #       { "element_id": "wall-1", "percent_complete": 50 },
        #       { "element_id": "door-1", "percent_complete": 100 }
        #     ]
        #   }
        #
        def bulk_update
          unless params[:model_id] && params[:updates]
            return render json: { error: 'model_id and updates required' }, status: :bad_request
          end

          model = ::Bim::IfcModels::IfcModel.find(params[:model_id])
          service = ::Bim::Progress::TrackingService.new(ifc_model: model, user: current_user)

          result = service.bulk_update_progress(params[:updates])

          if result.success?
            render json: {
              message: 'Bulk update successful',
              updated_count: result.result.size,
              progress: result.result.map { |p| serialize_progress(p) }
            }
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC model not found' }, status: :not_found
        end

        ##
        # Sync progress from linked work packages
        #
        # POST /api/v3/bim/progress/sync_work_packages
        #
        # Body:
        #   { "model_id": 123 }
        #
        def sync_work_packages
          unless params[:model_id]
            return render json: { error: 'model_id required' }, status: :bad_request
          end

          model = ::Bim::IfcModels::IfcModel.find(params[:model_id])
          service = ::Bim::Progress::TrackingService.new(ifc_model: model, user: current_user)

          result = service.sync_from_work_packages

          if result.success?
            render json: {
              message: 'Work package sync successful',
              synced_count: result.result[:synced_count]
            }
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC model not found' }, status: :not_found
        end

        ##
        # Get model progress statistics
        #
        # GET /api/v3/bim/progress/statistics?model_id=123
        #
        def statistics
          unless params[:model_id]
            return render json: { error: 'model_id required' }, status: :bad_request
          end

          model = ::Bim::IfcModels::IfcModel.find(params[:model_id])
          service = ::Bim::Progress::TrackingService.new(ifc_model: model)

          stats = service.calculate_model_progress

          render json: stats
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC model not found' }, status: :not_found
        end

        private

        def find_progress
          @progress = ::Bim::ElementProgress.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Element progress not found' }, status: :not_found
        end

        def progress_params
          params.permit(
            :percent_complete,
            :status,
            :planned_start,
            :planned_finish,
            :actual_start,
            :actual_finish,
            :work_package_id,
            :element_name,
            :element_type
          )
        end

        def authorize_view
          head :unauthorized unless current_user
        end

        def authorize_manage
          head :unauthorized unless current_user
        end

        def serialize_progress(progress, detailed: false)
          data = {
            id: progress.id,
            ifc_model_id: progress.ifc_model_id,
            element_id: progress.element_id,
            element_name: progress.element_name,
            element_type: progress.element_type,
            display_name: progress.display_name,
            status: progress.status,
            percent_complete: progress.percent_complete,
            baseline_id: progress.baseline_id,
            work_package_id: progress.work_package_id,
            updated_at: progress.updated_at,
            updated_by: progress.updated_by&.name
          }

          if detailed
            data.merge!(
              planned_start: progress.planned_start,
              planned_finish: progress.planned_finish,
              actual_start: progress.actual_start,
              actual_finish: progress.actual_finish,
              planned_duration_days: progress.planned_duration_days,
              actual_duration_days: progress.actual_duration_days,
              schedule_variance_days: progress.schedule_variance_days,
              delayed: progress.delayed?,
              ahead_of_schedule: progress.ahead_of_schedule?,
              progress_color: progress.progress_color,
              complete: progress.complete?,
              in_progress: progress.in_progress?,
              started: progress.started?
            )
          end

          data
        end
      end
    end
  end
end

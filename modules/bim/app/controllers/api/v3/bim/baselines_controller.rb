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
      # API Controller for Progress Baselines
      #
      # Endpoints:
      #   GET    /api/v3/bim/baselines       - List baselines
      #   GET    /api/v3/bim/baselines/:id   - Show baseline
      #   POST   /api/v3/bim/baselines       - Create baseline
      #   PATCH  /api/v3/bim/baselines/:id   - Update baseline
      #   DELETE /api/v3/bim/baselines/:id   - Delete baseline
      #   POST   /api/v3/bim/baselines/:id/snapshot - Create snapshot
      #   POST   /api/v3/bim/baselines/:id/set_current - Set as current
      #   GET    /api/v3/bim/baselines/:id/compare - Compare to current
      #
      class BaselinesController < ApplicationController
        before_action :find_baseline, only: %i[show update destroy snapshot set_current compare]
        before_action :authorize_view, only: %i[index show compare]
        before_action :authorize_manage, only: %i[create update destroy snapshot set_current]

        ##
        # List baselines with filtering and pagination
        #
        # Query parameters:
        #   - model_id: Filter by IFC model
        #   - is_current: Filter by current status
        #   - page: Page number (default: 1)
        #   - per_page: Results per page (default: 25, max: 100)
        #
        def index
          baselines = ::Bim::ProgressBaseline.all

          # Filtering
          baselines = baselines.for_model(params[:model_id]) if params[:model_id]
          baselines = baselines.current_baseline if params[:is_current] == 'true'

          # Pagination
          page = params[:page]&.to_i || 1
          per_page = [params[:per_page]&.to_i || 25, 100].min

          baselines = baselines.recent.page(page).per(per_page)

          render json: {
            baselines: baselines.map { |b| serialize_baseline(b) },
            total: baselines.total_count,
            page: page,
            per_page: per_page
          }
        end

        ##
        # Show single baseline
        #
        def show
          render json: serialize_baseline(@baseline, detailed: true)
        end

        ##
        # Create new baseline
        #
        # Parameters:
        #   - ifc_model_id: IFC model ID (required)
        #   - name: Baseline name (required)
        #   - description: Optional description
        #   - snapshot_date: Snapshot date (default: today)
        #   - create_snapshot: Whether to snapshot current progress (default: false)
        #
        def create
          baseline = ::Bim::ProgressBaseline.new(baseline_params)
          baseline.created_by = current_user

          if baseline.save
            baseline.create_snapshot! if params[:create_snapshot]

            render json: serialize_baseline(baseline, detailed: true), status: :created
          else
            render json: { errors: baseline.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Update baseline
        #
        def update
          if @baseline.update(baseline_params)
            render json: serialize_baseline(@baseline, detailed: true)
          else
            render json: { errors: @baseline.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Delete baseline
        #
        def destroy
          @baseline.destroy
          head :no_content
        end

        ##
        # Create snapshot of current progress
        #
        # POST /api/v3/bim/baselines/:id/snapshot
        #
        def snapshot
          @baseline.create_snapshot!
          render json: serialize_baseline(@baseline, detailed: true)
        rescue StandardError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        ##
        # Set baseline as current
        #
        # POST /api/v3/bim/baselines/:id/set_current
        #
        def set_current
          @baseline.set_as_current!
          render json: serialize_baseline(@baseline, detailed: true)
        rescue StandardError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        ##
        # Compare baseline to current progress
        #
        # GET /api/v3/bim/baselines/:id/compare
        #
        def compare
          service = ::Bim::Progress::TrackingService.new(ifc_model: @baseline.ifc_model)
          comparison = service.compare_to_baseline(@baseline)

          render json: comparison
        end

        private

        def find_baseline
          @baseline = ::Bim::ProgressBaseline.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Baseline not found' }, status: :not_found
        end

        def baseline_params
          params.require(:baseline).permit(
            :ifc_model_id,
            :name,
            :description,
            :snapshot_date,
            :is_current
          )
        rescue ActionController::ParameterMissing
          # Allow params at root level for convenience
          params.permit(
            :ifc_model_id,
            :name,
            :description,
            :snapshot_date,
            :is_current
          )
        end

        def authorize_view
          # TODO: Implement proper authorization
          # For now, require user to be logged in
          head :unauthorized unless current_user
        end

        def authorize_manage
          # TODO: Implement proper authorization
          # For now, require user to be logged in
          head :unauthorized unless current_user
        end

        def serialize_baseline(baseline, detailed: false)
          data = {
            id: baseline.id,
            ifc_model_id: baseline.ifc_model_id,
            name: baseline.name,
            description: baseline.description,
            snapshot_date: baseline.snapshot_date,
            is_current: baseline.is_current,
            total_elements: baseline.total_elements,
            completed_elements: baseline.completed_elements,
            overall_progress: baseline.overall_progress,
            completion_percentage: baseline.completion_percentage,
            created_at: baseline.created_at,
            created_by: baseline.created_by&.name
          }

          if detailed
            data.merge!(
              statistics: baseline.statistics,
              statistics_by_type: baseline.statistics_by_type,
              statistics_by_status: baseline.statistics_by_status
            )
          end

          data
        end
      end
    end
  end
end

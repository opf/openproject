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
      # API Controller for BIM Metrics
      #
      # Endpoints:
      #   GET /api/v3/bim/metrics?project_id=123 - Get aggregated project metrics
      #
      class MetricsController < ApplicationController
        before_action :authorize_view

        ##
        # Get aggregated project metrics
        #
        # Query parameters:
        #   - project_id: Project ID (required)
        #   - date_range: Number of days (default: 30)
        #   - include_sections: Comma-separated sections (models,clashes,issues,progress,work_packages,summary)
        #
        def index
          unless params[:project_id]
            return render json: { error: 'project_id required' }, status: :bad_request
          end

          project = Project.find(params[:project_id])
          days = params[:date_range]&.to_i || 30
          date_range = days.days.ago..Time.current

          service = ::Bim::Metrics::AggregatorService.new(
            project: project,
            date_range: date_range
          )

          metrics = service.call

          # Filter sections if requested
          if params[:include_sections]
            sections = params[:include_sections].split(',').map(&:to_sym)
            metrics = metrics.slice(*sections, :timestamp, :project_id, :date_range)
          end

          render json: metrics
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Project not found' }, status: :not_found
        end

        private

        def authorize_view
          head :unauthorized unless current_user
        end
      end
    end
  end
end

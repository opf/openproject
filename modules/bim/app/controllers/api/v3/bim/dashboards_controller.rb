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
      # API Controller for BIM Dashboards
      #
      # Endpoints:
      #   GET    /api/v3/bim/dashboards       - List dashboards
      #   GET    /api/v3/bim/dashboards/:id   - Show dashboard with widgets
      #   POST   /api/v3/bim/dashboards       - Create dashboard
      #   PATCH  /api/v3/bim/dashboards/:id   - Update dashboard
      #   DELETE /api/v3/bim/dashboards/:id   - Delete dashboard
      #   POST   /api/v3/bim/dashboards/:id/clone - Clone dashboard
      #   POST   /api/v3/bim/dashboards/:id/refresh - Refresh all widgets
      #   GET    /api/v3/bim/dashboards/default - Get default dashboard
      #
      class DashboardsController < ApplicationController
        before_action :find_dashboard, only: %i[show update destroy clone refresh]
        before_action :authorize_view, only: %i[index show default]
        before_action :authorize_manage, only: %i[create update destroy clone refresh]

        ##
        # List dashboards
        #
        # Query parameters:
        #   - project_id: Filter by project
        #   - user_id: Filter by user (optional, defaults to current_user)
        #   - is_default: Filter by default status
        #   - is_public: Filter by public status
        #
        def index
          dashboards = ::Bim::Dashboard.all

          # Filtering
          dashboards = dashboards.for_project(params[:project_id]) if params[:project_id]
          dashboards = dashboards.for_user(params[:user_id] || current_user.id) if params[:user_id] || current_user
          dashboards = dashboards.default_dashboards if params[:is_default] == 'true'
          dashboards = dashboards.public_dashboards if params[:is_public] == 'true'

          dashboards = dashboards.recent

          render json: {
            dashboards: dashboards.map { |d| serialize_dashboard(d) }
          }
        end

        ##
        # Show dashboard with widgets
        #
        # Query parameters:
        #   - include_data: Include widget data (default: false)
        #   - force_refresh: Force widget data refresh (default: false)
        #
        def show
          include_data = params[:include_data] == 'true'
          force_refresh = params[:force_refresh] == 'true'

          data = serialize_dashboard(@dashboard, detailed: true)

          if include_data
            data[:widgets] = @dashboard.render_widgets(force_refresh: force_refresh)
          else
            data[:widgets] = @dashboard.widgets.map { |w| serialize_widget(w) }
          end

          render json: data
        end

        ##
        # Create dashboard
        #
        # Parameters:
        #   - project_id: Project ID (required)
        #   - name: Dashboard name (required)
        #   - description: Description
        #   - is_default: Set as default
        #   - is_public: Set as public
        #   - layout_config: Grid layout configuration
        #
        def create
          dashboard = ::Bim::Dashboard.new(dashboard_params)
          dashboard.user = current_user unless dashboard.user

          if dashboard.save
            render json: serialize_dashboard(dashboard, detailed: true), status: :created
          else
            render json: { errors: dashboard.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Update dashboard
        #
        def update
          if @dashboard.update(dashboard_params)
            render json: serialize_dashboard(@dashboard, detailed: true)
          else
            render json: { errors: @dashboard.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Delete dashboard
        #
        def destroy
          @dashboard.destroy
          head :no_content
        end

        ##
        # Clone dashboard
        #
        # POST /api/v3/bim/dashboards/:id/clone
        #
        # Parameters:
        #   - user_id: Clone for this user (optional)
        #   - project_id: Clone for this project (optional)
        #
        def clone
          user = params[:user_id] ? User.find(params[:user_id]) : current_user
          project = params[:project_id] ? Project.find(params[:project_id]) : nil

          cloned = @dashboard.clone_for(user: user, project: project)

          render json: serialize_dashboard(cloned, detailed: true), status: :created
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'User or project not found' }, status: :not_found
        end

        ##
        # Refresh all widget caches
        #
        # POST /api/v3/bim/dashboards/:id/refresh
        #
        def refresh
          @dashboard.refresh_all_widgets!
          render json: {
            message: 'Dashboard refreshed',
            widgets_refreshed: @dashboard.widgets.count,
            dashboard: serialize_dashboard(@dashboard, detailed: true)
          }
        end

        ##
        # Get or create default dashboard for project
        #
        # GET /api/v3/bim/dashboards/default?project_id=123
        #
        def default
          unless params[:project_id]
            return render json: { error: 'project_id required' }, status: :bad_request
          end

          project = Project.find(params[:project_id])
          dashboard = ::Bim::Dashboard.default_for_project(project)

          render json: serialize_dashboard(dashboard, detailed: true)
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Project not found' }, status: :not_found
        end

        private

        def find_dashboard
          @dashboard = ::Bim::Dashboard.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Dashboard not found' }, status: :not_found
        end

        def dashboard_params
          params.require(:dashboard).permit(
            :project_id,
            :user_id,
            :name,
            :description,
            :is_default,
            :is_public,
            layout_config: {},
            settings: {}
          )
        rescue ActionController::ParameterMissing
          params.permit(
            :project_id,
            :user_id,
            :name,
            :description,
            :is_default,
            :is_public,
            layout_config: {},
            settings: {}
          )
        end

        def authorize_view
          head :unauthorized unless current_user
        end

        def authorize_manage
          head :unauthorized unless current_user
        end

        def serialize_dashboard(dashboard, detailed: false)
          data = {
            id: dashboard.id,
            project_id: dashboard.project_id,
            user_id: dashboard.user_id,
            name: dashboard.name,
            description: dashboard.description,
            is_default: dashboard.is_default,
            is_public: dashboard.is_public,
            created_at: dashboard.created_at,
            updated_at: dashboard.updated_at
          }

          if detailed
            data.merge!(
              layout_config: dashboard.layout_config,
              settings: dashboard.settings,
              metrics: dashboard.metrics_summary,
              widget_count: dashboard.widgets.count
            )
          end

          data
        end

        def serialize_widget(widget)
          {
            id: widget.id,
            widget_type: widget.widget_type,
            title: widget.title || widget.default_title,
            description: widget.description,
            position: widget.position,
            size: widget.size,
            config: widget.config,
            refresh_interval: widget.refresh_interval,
            cached_at: widget.cached_at
          }
        end
      end
    end
  end
end

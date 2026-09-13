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
      # API Controller for Dashboard Widgets
      #
      # Endpoints:
      #   GET    /api/v3/bim/widgets/:id   - Show widget with data
      #   POST   /api/v3/bim/widgets       - Create widget
      #   PATCH  /api/v3/bim/widgets/:id   - Update widget
      #   DELETE /api/v3/bim/widgets/:id   - Delete widget
      #   POST   /api/v3/bim/widgets/:id/refresh - Refresh widget data
      #
      class DashboardWidgetsController < ApplicationController
        before_action :find_widget, only: %i[show update destroy refresh]
        before_action :authorize_view, only: %i[show]
        before_action :authorize_manage, only: %i[create update destroy refresh]

        ##
        # Show widget with data
        #
        # Query parameters:
        #   - include_data: Include widget data (default: true)
        #   - force_refresh: Force data refresh (default: false)
        #
        def show
          include_data = params[:include_data] != 'false'
          force_refresh = params[:force_refresh] == 'true'

          data = serialize_widget(@widget)

          if include_data
            data[:data] = @widget.fetch_data(force_refresh: force_refresh)
            data[:last_updated] = @widget.cached_at || @widget.updated_at
          end

          render json: data
        end

        ##
        # Create widget
        #
        # Parameters:
        #   - dashboard_id: Dashboard ID (required)
        #   - widget_type: Widget type (required)
        #   - title: Widget title
        #   - position: Grid position {x, y}
        #   - size: Widget size {width, height}
        #   - config: Widget configuration
        #
        def create
          widget = ::Bim::DashboardWidget.new(widget_params)

          if widget.save
            widget.refresh_cache!
            render json: serialize_widget(widget, include_data: true), status: :created
          else
            render json: { errors: widget.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Update widget
        #
        def update
          if @widget.update(widget_params)
            @widget.refresh_cache! if should_refresh_after_update?
            render json: serialize_widget(@widget, include_data: true)
          else
            render json: { errors: @widget.errors.full_messages }, status: :unprocessable_entity
          end
        end

        ##
        # Delete widget
        #
        def destroy
          @widget.destroy
          head :no_content
        end

        ##
        # Refresh widget data
        #
        # POST /api/v3/bim/widgets/:id/refresh
        #
        def refresh
          @widget.refresh_cache!
          render json: {
            message: 'Widget refreshed',
            widget: serialize_widget(@widget, include_data: true)
          }
        end

        private

        def find_widget
          @widget = ::Bim::DashboardWidget.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Widget not found' }, status: :not_found
        end

        def widget_params
          params.require(:widget).permit(
            :dashboard_id,
            :widget_type,
            :title,
            :description,
            :refresh_interval,
            position: {},
            size: {},
            config: {}
          )
        rescue ActionController::ParameterMissing
          params.permit(
            :dashboard_id,
            :widget_type,
            :title,
            :description,
            :refresh_interval,
            position: {},
            size: {},
            config: {}
          )
        end

        def should_refresh_after_update?
          # Refresh if config changed
          saved_change_to_config? || saved_change_to_widget_type?
        end

        def authorize_view
          head :unauthorized unless current_user
        end

        def authorize_manage
          head :unauthorized unless current_user
        end

        def serialize_widget(widget, include_data: false)
          data = {
            id: widget.id,
            dashboard_id: widget.dashboard_id,
            widget_type: widget.widget_type,
            title: widget.title || widget.default_title,
            description: widget.description,
            position: widget.position,
            size: widget.size,
            config: widget.config,
            refresh_interval: widget.refresh_interval,
            cached_at: widget.cached_at,
            created_at: widget.created_at,
            updated_at: widget.updated_at
          }

          if include_data
            data[:data] = widget.fetch_data
            data[:last_updated] = widget.cached_at || widget.updated_at
          end

          data
        end
      end
    end
  end
end

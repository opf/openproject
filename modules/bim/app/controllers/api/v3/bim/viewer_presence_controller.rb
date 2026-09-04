# frozen_string_literal: true

module API
  module V3
    module Bim
      class ViewerPresenceController < ApplicationController
        before_action :find_ifc_model
        before_action :authorize

        # GET /api/v3/bim/ifc_models/:ifc_model_id/presence
        def index
          service = ::Bim::Collaboration::PresenceService.new(@ifc_model)

          render json: {
            _type: 'ViewerPresence',
            ifc_model_id: @ifc_model.id,
            active_viewers_count: service.active_viewers_count,
            viewers: service.presence_summary[:viewers]
          }
        end

        # POST /api/v3/bim/ifc_models/:ifc_model_id/presence
        def create
          service = ::Bim::Collaboration::PresenceService.new(@ifc_model)

          camera_position = params[:camera_position]
          presence = service.update_presence(
            user: current_user,
            camera_position: camera_position
          )

          # Broadcast presence change
          service.broadcast_presence_change(
            action: 'joined',
            user: current_user
          )

          render json: {
            _type: 'PresenceUpdate',
            message: 'Presence updated',
            user_id: current_user.id,
            last_seen_at: presence.last_seen_at,
            active_viewers: service.active_viewers_count
          }
        end

        # PUT/PATCH /api/v3/bim/ifc_models/:ifc_model_id/presence
        def update
          service = ::Bim::Collaboration::PresenceService.new(@ifc_model)

          camera_position = params[:camera_position]
          presence = service.update_presence(
            user: current_user,
            camera_position: camera_position
          )

          render json: {
            _type: 'PresenceUpdate',
            message: 'Presence updated',
            user_id: current_user.id,
            last_seen_at: presence.last_seen_at
          }
        end

        # DELETE /api/v3/bim/ifc_models/:ifc_model_id/presence
        def destroy
          service = ::Bim::Collaboration::PresenceService.new(@ifc_model)
          service.remove_presence(user: current_user)

          # Broadcast presence change
          service.broadcast_presence_change(
            action: 'left',
            user: current_user
          )

          head :no_content
        end

        private

        def find_ifc_model
          @ifc_model = ::Bim::IfcModels::IfcModel.find(params[:ifc_model_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC Model not found' }, status: :not_found
        end

        def authorize
          # Check if user has permission to view IFC models
          unless current_user.allowed_in_project?(:view_ifc_models, @ifc_model.project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
      end
    end
  end
end

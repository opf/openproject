# frozen_string_literal: true

module Bim
  module Collaboration
    class PresenceService
      def initialize(ifc_model)
        @ifc_model = ifc_model
      end

      # Update presence for a user
      def update_presence(user:, camera_position: nil)
        Bim::ViewerPresence.update_presence(
          ifc_model: @ifc_model,
          user: user,
          camera_position: camera_position
        )
      end

      # Remove presence for a user
      def remove_presence(user:)
        Bim::ViewerPresence.for_model(@ifc_model.id)
                           .for_user(user.id)
                           .destroy_all
      end

      # Get all active viewers
      def active_viewers
        Bim::ViewerPresence.active_viewers(@ifc_model)
      end

      # Get active viewers count
      def active_viewers_count
        active_viewers.count
      end

      # Get all presence records (including inactive)
      def all_presences
        Bim::ViewerPresence.for_model(@ifc_model.id)
                           .includes(:user)
                           .recent
      end

      # Check if a specific user is viewing
      def user_viewing?(user)
        Bim::ViewerPresence.for_model(@ifc_model.id)
                           .for_user(user.id)
                           .active
                           .exists?
      end

      # Get presence summary for broadcasting
      def presence_summary
        {
          total_viewers: active_viewers_count,
          viewers: active_viewers.map do |user|
            {
              id: user.id,
              name: user.name,
              login: user.login,
              initials: user_initials(user)
            }
          end
        }
      end

      # Cleanup stale presence records
      def self.cleanup_stale(threshold = 1.hour.ago)
        Bim::ViewerPresence.cleanup_stale_presence(threshold)
      end

      # Broadcast presence change to all viewers
      def broadcast_presence_change(action:, user:)
        return unless defined?(Turbo)

        Turbo::StreamsChannel.broadcast_update_to(
          "model_#{@ifc_model.id}_presence",
          target: "presence_indicator",
          html: render_presence_html
        )
      end

      private

      def user_initials(user)
        "#{user.firstname.to_s[0]}#{user.lastname.to_s[0]}".upcase
      end

      def render_presence_html
        # This would render a partial with current presence
        # For now, return empty string
        ''
      end
    end
  end
end

# frozen_string_literal: true

module Bim
  class ViewerPresence < ApplicationRecord
    self.table_name = 'bim_viewer_presence'

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user

    validates :ifc_model_id, uniqueness: { scope: :user_id }
    validates :user, presence: true
    validates :ifc_model, presence: true
    validates :last_seen_at, presence: true

    # Scopes
    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :active, -> { where('last_seen_at > ?', 5.minutes.ago) }
    scope :recent, -> { order(last_seen_at: :desc) }

    # Constants
    ACTIVE_THRESHOLD = 5.minutes

    # Class methods

    # Update or create presence for a user viewing a model
    def self.update_presence(ifc_model:, user:, camera_position: nil)
      presence = find_or_initialize_by(ifc_model: ifc_model, user: user)
      presence.last_seen_at = Time.current
      presence.camera_position = camera_position if camera_position
      presence.save!
      presence
    end

    # Get all active users viewing a model
    def self.active_viewers(ifc_model)
      for_model(ifc_model.id)
        .active
        .includes(:user)
        .map(&:user)
    end

    # Remove stale presence records
    def self.cleanup_stale_presence(threshold = 1.hour.ago)
      where('last_seen_at < ?', threshold).delete_all
    end

    # Instance methods

    # Check if user is currently active (seen within threshold)
    def active?
      last_seen_at > ACTIVE_THRESHOLD.ago
    end

    # Mark presence as seen now
    def touch_presence!(camera_position: nil)
      self.last_seen_at = Time.current
      self.camera_position = camera_position if camera_position
      save!
    end

    # Get formatted last seen time
    def last_seen_ago
      return 'just now' if active?

      distance_of_time_in_words(last_seen_at, Time.current)
    end

    # Get camera view data
    def camera_view
      camera_position || {}
    end

    # Export presence data for broadcasting
    def to_broadcast
      {
        user_id: user_id,
        user_name: user.name,
        user_login: user.login,
        user_avatar: user.avatar_url,
        last_seen_at: last_seen_at,
        active: active?,
        camera_position: camera_position
      }
    end

    private

    def distance_of_time_in_words(from_time, to_time)
      diff = (to_time - from_time).to_i

      case diff
      when 0..59
        'less than a minute ago'
      when 60..3599
        "#{diff / 60} minutes ago"
      when 3600..86_399
        "#{diff / 3600} hours ago"
      else
        "#{diff / 86_400} days ago"
      end
    end
  end
end

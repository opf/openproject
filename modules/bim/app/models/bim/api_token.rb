# frozen_string_literal: true

module Bim
  class ApiToken < ApplicationRecord
    self.table_name = 'bim_api_tokens'

    belongs_to :user
    belongs_to :project, optional: true # Optional for global tokens

    validates :name, presence: true, length: { maximum: 255 }
    validates :token_hash, presence: true, uniqueness: true
    validates :token_prefix, presence: true

    # Scopes
    scope :active, -> { where(active: true) }
    scope :expired, -> { where('expires_at IS NOT NULL AND expires_at < ?', Time.current) }
    scope :not_expired, -> { where('expires_at IS NULL OR expires_at >= ?', Time.current) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :recent, -> { order(created_at: :desc) }

    # Available scopes
    AVAILABLE_SCOPES = %w[
      read:models
      write:models
      delete:models
      read:clashes
      run:clashes
      read:baselines
      write:baselines
      read:federations
      write:federations
      read:dashboards
      write:dashboards
      admin:all
    ].freeze

    # Callbacks
    before_validation :set_token_prefix, on: :create

    # Class methods

    # Generate a new API token
    def self.generate(user:, name:, project: nil, scopes: [], expires_in: nil)
      token = SecureRandom.urlsafe_base64(32)
      token_hash = hash_token(token)
      token_prefix = token[0..7]

      api_token = create!(
        user: user,
        project: project,
        name: name,
        token_hash: token_hash,
        token_prefix: token_prefix,
        scopes: scopes,
        expires_at: expires_in ? Time.current + expires_in : nil
      )

      # Return both the token object and the plain token (only time it's visible)
      [api_token, token]
    end

    # Find token by plain token value
    def self.find_by_token(token)
      return nil unless token

      token_hash = hash_token(token)
      active.not_expired.find_by(token_hash: token_hash)
    end

    # Hash a token using SHA256
    def self.hash_token(token)
      Digest::SHA256.hexdigest(token)
    end

    # Cleanup expired tokens (call from scheduled job)
    def self.cleanup_expired(older_than: 30.days.ago)
      expired.where('expires_at < ?', older_than).delete_all
    end

    # Instance methods

    # Check if token has a specific scope
    def has_scope?(scope)
      return true if scopes.include?('admin:all')

      scopes.include?(scope)
    end

    # Check if token can perform action
    def can?(action, resource)
      scope_string = "#{action}:#{resource}"
      has_scope?(scope_string)
    end

    # Update last used timestamp
    def touch_last_used!(ip_address: nil)
      update!(
        last_used_at: Time.current,
        last_used_ip: ip_address,
        usage_count: usage_count + 1
      )
    end

    # Revoke token
    def revoke!
      update!(active: false)
    end

    # Check if token is valid
    def valid_token?
      active? && !expired?
    end

    # Check if token is expired
    def expired?
      expires_at.present? && expires_at < Time.current
    end

    # Get days until expiration
    def days_until_expiration
      return nil unless expires_at

      ((expires_at - Time.current) / 1.day).ceil
    end

    # Get human-readable status
    def status
      return 'revoked' unless active?
      return 'expired' if expired?

      'active'
    end

    # Get formatted expiration info
    def expiration_info
      return 'Never expires' unless expires_at

      if expired?
        "Expired #{time_ago_in_words(expires_at)} ago"
      else
        "Expires in #{days_until_expiration} days"
      end
    end

    # Export token info (without sensitive data)
    def to_hash
      {
        id: id,
        name: name,
        description: description,
        token_prefix: token_prefix,
        scopes: scopes,
        active: active,
        status: status,
        expires_at: expires_at&.iso8601,
        expiration_info: expiration_info,
        created_at: created_at.iso8601,
        last_used_at: last_used_at&.iso8601,
        usage_count: usage_count,
        user: {
          id: user.id,
          name: user.name,
          login: user.login
        },
        project: project ? { id: project.id, name: project.name } : nil
      }
    end

    private

    def set_token_prefix
      # Token prefix is set during generation
      # This callback is just a safety check
      self.token_prefix ||= SecureRandom.hex(4)
    end

    def time_ago_in_words(time)
      distance_of_time_in_words_to_now(time)
    rescue StandardError
      'some time'
    end

    def distance_of_time_in_words_to_now(time)
      diff = (Time.current - time).to_i.abs

      case diff
      when 0..59
        'less than a minute'
      when 60..3599
        "#{diff / 60} minutes"
      when 3600..86_399
        "#{diff / 3600} hours"
      else
        "#{diff / 86_400} days"
      end
    end
  end
end

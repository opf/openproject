# frozen_string_literal: true

module TestManagement
  # Test Assistant "Chat" history (0014), kept per user and per project. Assistant messages may
  # carry a proposed write (action) that only runs after the user confirms it.
  #   action         { "name" => "create_test_run", "params" => {...}, "preview" => [...], "errors" => [...] }
  #   action_status  proposed | confirmed | cancelled | failed
  #   action_result  { "records" => [{ "type", "id", "title" }] } or { "errors" => [...] }
  class AssistantMessage < ApplicationRecord
    self.table_name = "tm_assistant_messages"

    ROLES = %w[user assistant].freeze
    STATES = %w[pending done failed].freeze
    ACTION_STATUSES = %w[proposed confirmed cancelled failed].freeze
    MAX_CONTENT = 4000
    STALE_AFTER = 10.minutes

    belongs_to :project
    belongs_to :user
    # 0021: the saved provider asked (nil when it was deleted or for requests before 0021)
    belongs_to :provider, class_name: "TestManagement::AssistantProvider", optional: true

    validates :role, inclusion: { in: ROLES }
    validates :state, inclusion: { in: STATES }
    validates :action_status, inclusion: { in: ACTION_STATUSES }, allow_nil: true

    scope :ordered, -> { order(:id) }

    def self.of(user, project)
      where(user_id: user.id, project_id: project.id)
    end

    def assistant?
      role == "assistant"
    end

    def pending?
      state == "pending" && !stale?
    end

    def stale?
      state == "pending" && updated_at.present? && updated_at < STALE_AFTER.ago
    end

    def failed?
      state == "failed" || stale?
    end

    def action_data
      action.present? ? action.to_h.stringify_keys : nil
    end

    def proposal?
      action_data.present?
    end

    def action_errors
      Array(action_data&.dig("errors"))
    end

    def confirmable?
      proposal? && action_status == "proposed" && action_errors.empty?
    end

    def result_data
      (action_result || {}).to_h.stringify_keys
    end
  end
end

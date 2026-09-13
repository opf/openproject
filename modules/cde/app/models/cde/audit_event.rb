# frozen_string_literal: true

module Cde
  class AuditEvent < ApplicationRecord
    self.table_name = 'cde_audit_events'

    belongs_to :auditable, polymorphic: true
    belongs_to :user, class_name: 'User'

    # Validations
    validates :action, presence: true
    validates :user, presence: true
    validates :event_type, presence: true

    # Scope methods
    def self.for_container(container)
      where(auditable: container)
        .or(where(auditable: container.revisions))
        .order(created_at: :desc)
    end

    def self.recent(hours: 24)
      where('created_at > ?', hours.hours.ago)
        .order(created_at: :desc)
    end

    def self.by_action(action)
      where(action: action)
    end

    def self.by_user(user)
      where(user: user)
    end
  end
end

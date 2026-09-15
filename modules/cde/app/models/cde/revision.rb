# frozen_string_literal: true

module Cde
  class Revision < ApplicationRecord
    self.table_name = 'cde_revisions'

    belongs_to :container, class_name: 'Cde::Container'
    belongs_to :author, class_name: 'User', optional: true

    has_many :audit_events, class_name: 'Cde::AuditEvent', as: :auditable, dependent: :destroy

    # Lifecycle states
    enum status: {
      working: 0,
      preliminary: 1,
      contractual: 2,
      published: 3,
      superseded: 4
    }

    # Validations
    validates :revision_code, presence: true
    validates :revision_code, format: {
      with: /\A[PAC]\d{2}(\.\d{2})?\z/,
      message: 'must match format: P01, P01.01, C01, A01'
    }
    validates :revision_code, uniqueness: { scope: :container_id }

    # Callbacks
    before_save :enforce_working_revision_invariant
    after_update :audit_revision_update, if: :saved_change_to_status?

    # Class methods
    def self.active(container)
      container.revisions.where.not(status: :superseded)
    end

    def self.current_working(container)
      container.revisions.where(is_working: true, status: :working)
    end

    def self.published(container)
      container.revisions.where(status: :published).order(published_at: :desc)
    end

    private

    def enforce_working_revision_invariant
      if is_working && status == :working
        # Deactivate other working revisions for this container
        container.revisions.where(is_working: true).where.not(id: id).update_all(is_working: false)
      end
    end

    def audit_revision_update
      Cde::AuditEvent.create!(
        auditable: self,
        user: author,
        action: 'revision.updated',
        event_type: 'update',
        old_state: { status: status_before_last_save },
        new_state: { status: status },
        reason: 'Status changed'
      )
    end

    def status_before_last_save
      # This would be implemented with a callback or stored in a separate column
      # For now, return nil (will be improved in Slice 2)
      nil
    end
  end
end

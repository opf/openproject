# frozen_string_literal: true

module Cde
  class Suitability < ApplicationRecord
    self.table_name = 'cde_suitabilities'

    belongs_to :container, class_name: 'Cde::Container'
    belongs_to :assigner, class_name: 'User'

    # ISO 19650 suitability codes
    # S0: Suitable for use without review
    # S1: Suitable for review
    # S2: Suitable for coordination
    # A1: Approved for construction
    # A2: Approved as built
    # D1: Rejected / Do not use
    enum code: {
      s0: 0,
      s1: 1,
      s2: 2,
      a1: 3,
      a2: 4,
      d1: 5
    }

    # Validations
    validates :code, presence: true
    validates :code, inclusion: { in: Suitability.codes.keys }

    # Callbacks
    after_create :audit_suitability_assignment

    private

    def audit_suitability_assignment
      Cde::AuditEvent.create!(
        auditable: container,
        user: assigner,
        action: 'suitability.assigned',
        event_type: 'update',
        old_state: { suitability: nil },
        new_state: { suitability: code },
        reason: 'Suitability assigned during publication workflow'
      )
    end
  end
end

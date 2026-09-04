# frozen_string_literal: true

module Cde
  class Metadata < ApplicationRecord
    self.table_name = 'cde_metadata'

    belongs_to :container, class_name: 'Cde::Container'
    belongs_to :revision, class_name: 'Cde::Revision', optional: true

    # Controlled vocabulary fields
    enum discipline: {
      architectural: 0,
      structural: 1,
      mep: 2,
      civil: 3,
      electrical: 4,
      mechanical: 5,
      plumbing: 6,
      fire_protection: 7,
      telecommunications: 8,
      other: 9
    }

    enum container_type: {
      drawing: 0,
      model: 1,
      specification: 2,
      report: 3,
      calculation: 4,
      photograph: 5,
      email: 6,
      other: 7
    }

    # Validations
    validates :discipline, presence: true
    validates :container_type, presence: true
    validates :originator, presence: true

    # Scope methods
    def self.by_discipline(discipline)
      where(discipline: discipline)
    end

    def self.by_container_type(container_type)
      where(container_type: container_type)
    end

    def self.by_originator(originator)
      where(originator: originator)
    end
  end
end

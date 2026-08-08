# frozen_string_literal: true

module Cde
  class Container < ApplicationRecord
    self.table_name = 'cde_containers'

    # Association with OpenProject project
    belongs_to :project, class_name: 'Project'

    # Ownership
    belongs_to :owner, class_name: 'User', optional: true

    # Revisions
    has_many :revisions, class_name: 'Cde::Revision', dependent: :destroy
    has_one :working_revision, -> { where(is_working: true) }, class_name: 'Cde::Revision'
    has_one :latest_published_revision, -> { where(published: true).order(published_at: :desc) }, class_name: 'Cde::Revision'

    # Metadata
    has_many :metadata_entries, class_name: 'Cde::Metadata', dependent: :destroy

    # Audit events
    has_many :audit_events, class_name: 'Cde::AuditEvent', as: :auditable, dependent: :destroy

    # Suitability
    has_one :suitability, class_name: 'Cde::Suitability', dependent: :destroy

    # Lifecycle state
    enum status: { wip: 0, shared: 1, published: 2, archived: 3 }

    # Validations
    validates :identifier, presence: true, uniqueness: { scope: :project_id }
    validates :identifier, format: { with: -> { Cde::Conventions.container_id_validator }, message: 'does not match project convention' }

    # Callbacks
    before_create :initialize_revisions
    before_save :validate_identifier_uniqueness

    # Class methods
    def self.by_status(status)
      where(status: status)
    end

    def self.published
      where(status: :published)
    end

    def self.search(query = nil, filters: {})
      result = all
      result = result.joins(:project).where('projects.name LIKE ?', "%#{query}%") if query.present?
      result = result.where(status: filters[:status]) if filters[:status].present?
      result
    end

    private

    def initialize_revisions
      revisions.create!(
        revision_code: 'P01',
        is_working: true,
        status: :working
      )
    end

    def validate_identifier_uniqueness
      unless Cde::IdentifierValidator.valid?(identifier, project_id)
        errors.add(:identifier, 'must be unique within project')
      end
    end
  end
end

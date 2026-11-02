# frozen_string_literal: true

module TestManagement
  # A named group of configurations in a project (e.g. "Browsers", "Operating Systems").
  # Managed in Project settings → Test management. Optional for runs and plan entries.
  class ConfigurationGroup < ApplicationRecord
    self.table_name = "tm_configuration_groups"

    belongs_to :project
    has_many :configurations,
             -> { order(:id) },
             class_name: "TestManagement::Configuration",
             foreign_key: :configuration_group_id,
             inverse_of: :configuration_group,
             dependent: :destroy

    validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :project_id, case_sensitive: false }

    scope :ordered, -> { order(:name, :id) }
  end
end

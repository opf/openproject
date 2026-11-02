# frozen_string_literal: true

module TestManagement
  # A single configuration value inside a group (e.g. "Chrome" in "Browsers").
  class Configuration < ApplicationRecord
    self.table_name = "tm_configurations"

    belongs_to :configuration_group, class_name: "TestManagement::ConfigurationGroup", inverse_of: :configurations

    has_one :project, through: :configuration_group

    validates :name, presence: true, length: { maximum: 255 },
                     uniqueness: { scope: :configuration_group_id, case_sensitive: false }

    scope :ordered, -> { order(:name, :id) }

    # Cartesian product of selected configurations across groups (TestRail matrix).
    # Returns an array of arrays of Configuration records (one combination each).
    # No ids → one empty combination (a single unconfigured run).
    def self.combinations_for(configuration_ids)
      ids = Array(configuration_ids).map(&:to_i).reject(&:zero?).uniq
      return [[]] if ids.empty?

      configs = where(id: ids).includes(:configuration_group).to_a
      return [[]] if configs.empty?

      by_group = configs.group_by(&:configuration_group_id).values
      by_group[0].product(*by_group[1..])
    end

    def self.label_for(configuration_ids)
      combo = combinations_for(configuration_ids).first
      return nil if combo.blank?

      combo.map(&:name).join(", ")
    end
  end
end

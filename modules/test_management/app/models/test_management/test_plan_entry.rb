# frozen_string_literal: true

module TestManagement
  # A named group inside a test plan: case selection + optional configuration matrix.
  # Saving an entry spawns one TestRun per configuration combination (or one run if none).
  class TestPlanEntry < ApplicationRecord
    self.table_name = "tm_test_plan_entries"

    SELECTION_MODES = TestRun::SELECTION_MODES

    belongs_to :test_plan, class_name: "TestManagement::TestPlan", inverse_of: :entries
    belongs_to :assigned_to, class_name: "User", optional: true

    has_many :test_runs,
             class_name: "TestManagement::TestRun",
             inverse_of: :test_plan_entry,
             dependent: :nullify

    validates :name, presence: true, length: { maximum: 255 }
    validates :selection_mode, inclusion: { in: SELECTION_MODES }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def project
      test_plan&.project
    end

    def selected_case_ids
      Array(case_ids).map(&:to_i).reject(&:zero?)
    end

    def selected_configuration_ids
      Array(configuration_ids).map(&:to_i).reject(&:zero?)
    end

    def configuration_combinations
      Configuration.combinations_for(selected_configuration_ids)
    end

    def filter_label_ids
      Array(filter_options&.dig("label_ids")).map(&:to_i).reject(&:zero?)
    end

    def filter_suite_ids
      Array(filter_options&.dig("suite_ids")).map(&:to_i).reject(&:zero?)
    end

    def filter_automation
      value = filter_options&.dig("automation").to_s
      TestRun::AUTOMATION_FILTERS.include?(value) ? value : "any"
    end
  end
end

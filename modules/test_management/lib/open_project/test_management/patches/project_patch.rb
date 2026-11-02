# frozen_string_literal: true

module OpenProject::TestManagement::Patches
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        has_many :tm_suites,
                 class_name: "TestManagement::Suite",
                 dependent: :destroy
        has_many :tm_test_cases,
                 class_name: "TestManagement::TestCase",
                 dependent: :destroy
        has_many :tm_labels,
                 class_name: "TestManagement::Label",
                 dependent: :delete_all
        has_many :tm_test_runs,
                 class_name: "TestManagement::TestRun",
                 dependent: :destroy
        has_many :tm_ci_connections,
                 class_name: "TestManagement::CiConnection",
                 dependent: :delete_all
        has_many :tm_milestones,
                 class_name: "TestManagement::Milestone",
                 dependent: :delete_all
        has_many :tm_configuration_groups,
                 class_name: "TestManagement::ConfigurationGroup",
                 dependent: :destroy
        has_many :tm_test_plans,
                 class_name: "TestManagement::TestPlan",
                 dependent: :destroy
        has_one :tm_setting,
                class_name: "TestManagement::ProjectSetting",
                dependent: :destroy
      end
    end
  end
end

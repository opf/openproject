# frozen_string_literal: true

module OpenProject::TestManagement::Patches
  module WorkPackagePatch
    def self.included(base)
      base.class_eval do
        # Rows are also removed by the FK (on_delete: cascade); delete_all keeps
        # the in-memory association consistent when destroying through Rails.
        has_many :tm_test_case_work_packages,
                 class_name: "TestManagement::TestCaseWorkPackage",
                 dependent: :delete_all
        has_many :tm_test_cases,
                 through: :tm_test_case_work_packages,
                 source: :test_case,
                 class_name: "TestManagement::TestCase"
        has_many :tm_milestone_work_packages,
                 class_name: "TestManagement::MilestoneWorkPackage",
                 dependent: :delete_all
      end
    end
  end
end

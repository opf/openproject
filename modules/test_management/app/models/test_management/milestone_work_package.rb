# frozen_string_literal: true

module TestManagement
  # "References" of a milestone: linked work packages (like TestCaseWorkPackage / TestRunWorkPackage).
  class MilestoneWorkPackage < ApplicationRecord
    self.table_name = "tm_milestone_work_packages"

    belongs_to :milestone, class_name: "TestManagement::Milestone", inverse_of: :milestone_work_packages
    belongs_to :work_package

    validates :work_package_id, uniqueness: { scope: :milestone_id }, if: -> { milestone_id.present? }
  end
end

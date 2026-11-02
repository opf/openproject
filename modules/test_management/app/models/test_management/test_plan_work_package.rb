# frozen_string_literal: true

module TestManagement
  class TestPlanWorkPackage < ApplicationRecord
    self.table_name = "tm_test_plan_work_packages"

    belongs_to :test_plan, class_name: "TestManagement::TestPlan", inverse_of: :test_plan_work_packages
    belongs_to :work_package

    validates :work_package_id, uniqueness: { scope: :test_plan_id }
  end
end

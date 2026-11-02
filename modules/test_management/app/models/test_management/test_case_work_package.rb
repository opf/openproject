# frozen_string_literal: true

module TestManagement
  class TestCaseWorkPackage < ApplicationRecord
    self.table_name = "tm_test_case_work_packages"

    belongs_to :test_case, class_name: "TestManagement::TestCase", inverse_of: :test_case_work_packages
    belongs_to :work_package

    validates :work_package_id, uniqueness: { scope: :test_case_id }
  end
end

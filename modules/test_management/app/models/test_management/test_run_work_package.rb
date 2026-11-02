# frozen_string_literal: true

module TestManagement
  # "References" of a test run: linked work packages.
  class TestRunWorkPackage < ApplicationRecord
    self.table_name = "tm_test_run_work_packages"

    belongs_to :test_run, class_name: "TestManagement::TestRun", inverse_of: :test_run_work_packages
    belongs_to :work_package

    validates :work_package_id, uniqueness: { scope: :test_run_id }, if: -> { test_run_id.present? }
  end
end

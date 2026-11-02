# frozen_string_literal: true

module TestManagement
  class TestCaseLabel < ApplicationRecord
    self.table_name = "tm_test_case_labels"

    belongs_to :test_case, class_name: "TestManagement::TestCase", inverse_of: :test_case_labels
    belongs_to :label, class_name: "TestManagement::Label", inverse_of: :test_case_labels, autosave: true

    validates :label_id, uniqueness: { scope: :test_case_id }, if: -> { label_id.present? }
  end
end

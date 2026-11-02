# frozen_string_literal: true

module TestManagement
  class TestStep < ApplicationRecord
    self.table_name = "tm_test_steps"

    belongs_to :test_case, class_name: "TestManagement::TestCase", inverse_of: :steps

    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end

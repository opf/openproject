# frozen_string_literal: true

module TestManagement
  module TestCases
    class DeleteContract < ::DeleteContract
      delete_permission :delete_test_cases
    end
  end
end

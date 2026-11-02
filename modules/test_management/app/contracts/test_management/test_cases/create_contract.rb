# frozen_string_literal: true

module TestManagement
  module TestCases
    class CreateContract < BaseContract
      private

      def permitted?
        user.allowed_in_project?(:add_test_cases, model.project)
      end
    end
  end
end

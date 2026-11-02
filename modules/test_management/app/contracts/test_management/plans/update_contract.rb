# frozen_string_literal: true

module TestManagement
  module Plans
    class UpdateContract < BaseContract
      validate :plan_not_finished

      private

      def plan_not_finished
        return unless model.completed?

        errors.add :base, :error_readonly
      end
    end
  end
end

# frozen_string_literal: true

module TestManagement
  module Plans
    class TransitionService
      def initialize(user:, model:)
        @user = user
        @plan = model
      end

      def call
        return failure(:error_unauthorized) unless permitted?
        return failure(:tm_plans_disabled) unless TestManagement::ProjectSetting.plans_enabled?(plan.project)
        return failure(:tm_invalid_transition) unless allowed_from.include?(plan.state)

        TestPlan.transaction { perform }
        ServiceResult.success(result: plan)
      rescue ActiveRecord::RecordInvalid => e
        plan.errors.add(:base, e.message)
        ServiceResult.failure(result: plan, errors: plan.errors)
      end

      private

      attr_reader :user, :plan

      def permitted?
        user.allowed_in_project?(:manage_test_plans, plan.project)
      end

      def allowed_from
        raise TestManagement::AbstractMethodError
      end

      def perform
        raise TestManagement::AbstractMethodError
      end

      def failure(error)
        plan.errors.add(:base, error)
        ServiceResult.failure(result: plan, errors: plan.errors)
      end
    end
  end
end

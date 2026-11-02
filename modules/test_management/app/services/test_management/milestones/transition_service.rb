# frozen_string_literal: true

module TestManagement
  module Milestones
    # Start / complete / reopen / delete a milestone. Dates never change the status; only
    # these explicit actions do (as in common test management tools).
    class TransitionService
      def initialize(user:, model:)
        @user = user
        @milestone = model
      end

      def call
        return failure(:error_unauthorized) unless permitted?
        return failure(:tm_milestones_disabled) unless TestManagement::ProjectSetting.milestones_enabled?(milestone.project)
        return failure(:tm_invalid_transition) unless allowed_from.include?(milestone.status)

        Milestone.transaction { perform }
        ServiceResult.success(result: milestone)
      rescue ActiveRecord::RecordInvalid => e
        milestone.errors.add(:base, e.message)
        ServiceResult.failure(result: milestone, errors: milestone.errors)
      end

      private

      attr_reader :user, :milestone

      def permitted?
        user.allowed_in_project?(:manage_test_milestones, milestone.project)
      end

      def allowed_from
        raise TestManagement::AbstractMethodError
      end

      def perform
        raise TestManagement::AbstractMethodError
      end

      def failure(error)
        milestone.errors.add(:base, error)
        ServiceResult.failure(result: milestone, errors: milestone.errors)
      end
    end
  end
end

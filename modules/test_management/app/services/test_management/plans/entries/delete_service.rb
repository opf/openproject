# frozen_string_literal: true

module TestManagement
  module Plans
    module Entries
      class DeleteService
        def initialize(user:, model:)
          @user = user
          @entry = model
        end

        def call
          unless user.allowed_in_project?(:manage_test_plans, entry.test_plan.project)
            entry.errors.add(:base, :error_unauthorized)
            return ServiceResult.failure(result: entry, errors: entry.errors)
          end

          TestPlanEntry.transaction do
            entry.test_runs.find_each(&:destroy!)
            entry.destroy!
          end
          ServiceResult.success(result: entry)
        rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
          entry.errors.add(:base, e.message)
          ServiceResult.failure(result: entry, errors: entry.errors)
        end

        private

        attr_reader :user, :entry
      end
    end
  end
end

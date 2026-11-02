# frozen_string_literal: true

module TestManagement
  module Plans
    class UpdateService < ::BaseServices::Update
      protected

      def after_perform(call)
        propagate_milestone(call.result) if call.success?
        call
      end

      def propagate_milestone(plan)
        change = plan.saved_change_to_milestone_id
        return unless change

        previous_id = change.first
        plan.test_runs.active.find_each do |run|
          next if run.milestone_id.present? && run.milestone_id != previous_id

          run.update!(milestone_id: plan.milestone_id)
        end
      end
    end
  end
end

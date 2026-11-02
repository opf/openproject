# frozen_string_literal: true

module TestManagement
  module TestCases
    # Deep-copies a case into a target folder. Automation reference is cleared
    # (unique per project). Steps, labels and work-package links are copied.
    class CopyService
      def initialize(user:, model:)
        @user = user
        @model = model
      end

      def call(suite_id:)
        CreateService
          .new(user:)
          .call(copy_attributes(suite_id:))
      end

      private

      attr_reader :user, :model

      def copy_attributes(suite_id:)
        {
          project: model.project,
          title: model.title,
          description: model.description,
          preconditions: model.preconditions,
          priority: model.priority,
          status: model.status,
          automated: model.automated,
          automation_reference: nil,
          suite_id:,
          label_names: model.labels.map(&:name),
          work_package_ids: model.work_packages.pluck(:id),
          steps_attributes: model.steps.map do |step|
            {
              position: step.position,
              action: step.action,
              expected_result: step.expected_result,
              data: step.data
            }
          end
        }
      end
    end
  end
end

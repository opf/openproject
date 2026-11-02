# frozen_string_literal: true

module TestManagement
  module TestCases
    class RestoreService
      def initialize(user:, model:)
        @user = user
        @model = model
      end

      def call(suite_id: :keep)
        return failure(:not_deleted) unless model.deleted?
        return failure(:error_unauthorized) unless permitted?

        target = resolve_suite_id(suite_id)
        return target if target.is_a?(ServiceResult)

        previous_path = model.deleted_from_suite_path
        model.restore!(suite_id: target)
        model.events.create!(
          action: "restored",
          user_id: user.id,
          details: restore_details(previous_path, target)
        )
        ServiceResult.success(result: model)
      rescue ActiveRecord::RecordInvalid => e
        ServiceResult.failure(result: model, errors: e.record.errors)
      end

      private

      attr_reader :user, :model

      def permitted?
        user.allowed_in_project?(:edit_test_cases, model.project)
      end

      def resolve_suite_id(suite_id)
        if suite_id == :keep
          return failure(:folder_required) if model.restore_needs_folder?

          return model.deleted_from_suite_id
        end

        normalized = suite_id.presence
        return nil if normalized.blank? || normalized.to_s == "root"

        suite = Suite.find_by(id: normalized, project_id: model.project_id)
        return failure(:invalid_folder) unless suite

        suite.id
      end

      def restore_details(previous_path, suite_id)
        new_name = suite_id && Suite.find_by(id: suite_id)&.name
        return {} if previous_path.blank? && new_name.blank?

        { "suite_id" => [previous_path.presence || "—", new_name.presence || "—"] }
      end

      def failure(key)
        result = ServiceResult.failure(result: model)
        result.errors.add(:base, I18n.t("test_management.cases.restore_errors.#{key}"))
        result
      end
    end
  end
end

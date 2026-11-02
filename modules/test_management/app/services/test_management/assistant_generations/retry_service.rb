# frozen_string_literal: true

module TestManagement
  module AssistantGenerations
    class RetryService
      def initialize(user:, model:)
        @user = user
        @model = model
      end

      def call
        return unauthorized unless owned?
        return unavailable unless %w[failed cancelled].include?(model.effective_status)

        model.with_lock do
          model.reload
          return unavailable unless %w[failed cancelled].include?(model.effective_status)

          model.update!(status: "queued", progress_step: "queued", error: nil, drafts: [],
                        saved_case_ids: [], progress_done: nil, progress_total: nil, usage: nil)
        end

        TestManagement::Assistant::GenerateJob.perform_later(model.id)
        ServiceResult.success(result: model.reload)
      end

      private

      attr_reader :user, :model

      def owned?
        model.user_id == user.id
      end

      def unauthorized
        model.errors.add(:base, :error_unauthorized)
        ServiceResult.failure(result: model, errors: model.errors)
      end

      def unavailable
        model.errors.add(:base, :invalid)
        ServiceResult.failure(result: model, errors: model.errors)
      end
    end
  end
end

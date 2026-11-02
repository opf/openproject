# frozen_string_literal: true

module TestManagement
  module AssistantGenerations
    class CancelService
      def initialize(user:, model:)
        @user = user
        @model = model
      end

      def call
        return ServiceResult.failure(errors: model.errors) unless owned?

        model.with_lock do
          model.reload
          model.update!(status: "cancelled", error: nil) if model.pending?
        end

        ServiceResult.success(result: model.reload)
      end

      private

      attr_reader :user, :model

      def owned?
        model.user_id == user.id
      end
    end
  end
end

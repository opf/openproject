# frozen_string_literal: true

module TestManagement
  module Assistant
    # The confirmation gate: a proposed chat action runs only here, after the user pressed
    # Confirm on its card. Only the owner of the conversation can confirm; the assistant must
    # still be allowed for them; the action runs once (a repeated confirm is a no-op) through
    # the existing services, whose contracts check permissions again.
    class ConfirmActionService
      Result = Struct.new(:success, :message, :errors, keyword_init: true) do
        def success? = success
      end

      def initialize(user:, message:)
        @user = user
        @message = message
      end

      def call
        return failure(I18n.t(:notice_not_authorized)) unless owner? && Assistant.allowed?(user, message.project)

        message.with_lock { confirm_locked }
      end

      def cancel
        return failure(I18n.t(:notice_not_authorized)) unless owner?

        message.with_lock do
          if message.action_status == "proposed"
            message.update!(action_status: "cancelled")
            Result.new(success: true, message:, errors: [])
          else
            failure(I18n.t("test_management.assistant.chat.not_confirmable"))
          end
        end
      end

      private

      attr_reader :user, :message

      def confirm_locked
        if message.action_status == "confirmed"
          Result.new(success: true, message:, errors: [])
        elsif !message.confirmable?
          failure(I18n.t("test_management.assistant.chat.not_confirmable"))
        else
          outcome = Actions.execute(message.action_data, user:, project: message.project)
          if outcome.success?
            message.update!(action_status: "confirmed", action_result: { "records" => outcome.records })
            Result.new(success: true, message:, errors: [])
          else
            message.update!(action_status: "failed", action_result: { "errors" => outcome.errors })
            failure(*outcome.errors)
          end
        end
      end

      def owner?
        message.user_id == user.id && message.assistant? && message.proposal?
      end

      def failure(*errors)
        Result.new(success: false, message:, errors:)
      end
    end
  end
end

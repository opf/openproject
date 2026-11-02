# frozen_string_literal: true

module TestManagement
  module AssistantMessages
    # Stores the user's question, adds the pending assistant answer and queues ChatJob.
    class CreateService < ::BaseServices::Create
      protected

      def after_perform(call)
        return call unless call.success?

        question = call.result
        answer = TestManagement::AssistantMessage.create!(project: question.project, user: question.user,
                                                          role: "assistant", state: "pending",
                                                          provider_id: question.provider_id, chosen_model: question.chosen_model)
        TestManagement::Assistant::ChatJob.perform_later(answer.id)
        call
      end
    end
  end
end

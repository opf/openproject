# frozen_string_literal: true

module TestManagement
  module AssistantGenerations
    # Records a generation request and queues TestManagement::Assistant::GenerateJob.
    class CreateService < ::BaseServices::Create
      protected

      def after_perform(call)
        TestManagement::Assistant::GenerateJob.perform_later(call.result.id) if call.success?
        call
      end
    end
  end
end

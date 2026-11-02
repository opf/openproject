# frozen_string_literal: true

module TestManagement
  module TestRuns
    class CreateService < ::BaseServices::Create
      protected

      def after_perform(call)
        SyncCasesService.new(call.result).call if call.success?
        call
      end
    end
  end
end

# frozen_string_literal: true

module TestManagement
  module Plans
    module Entries
      class UpdateService < ::BaseServices::Update
        protected

        def after_perform(call)
          return call unless call.success?

          spawn = Runs::SpawnFromEntryService.new(user:, entry: call.result).call
          return spawn unless spawn.success?

          call
        end
      end
    end
  end
end

# frozen_string_literal: true

module TestManagement
  module TestRuns
    class UpdateContract < BaseContract
      validate :run_not_finished

      private

      # A completed/cancelled run is read-only until it is reopened.
      def run_not_finished
        errors.add :base, :tm_run_finished if model.finished? && !model.state_changed?
      end
    end
  end
end

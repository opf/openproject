# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # Inbound-only connections (0015): OpenProject does not call the CI server (one-way
      # networks, CI -> OpenProject only). The run and iteration are prepared as usual and the
      # outcome is "manual"; the run page shows the values to start the pipeline by hand
      # (CiTriggers::ManualStart).
      class Manual < Base
        protected

        def dispatch(ref:, inputs:) # rubocop:disable Lint/UnusedMethodArgument
          Result.new(status: "manual")
        end
      end
    end
  end
end

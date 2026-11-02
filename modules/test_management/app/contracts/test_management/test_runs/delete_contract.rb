# frozen_string_literal: true

module TestManagement
  module TestRuns
    class DeleteContract < ::DeleteContract
      delete_permission :delete_test_runs
    end
  end
end

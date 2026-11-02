# frozen_string_literal: true

module TestManagement
  module CiConnections
    class DeleteContract < ::DeleteContract
      delete_permission :manage_test_ci
    end
  end
end

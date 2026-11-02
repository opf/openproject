# frozen_string_literal: true

module TestManagement
  module Labels
    class DeleteContract < ::DeleteContract
      delete_permission :manage_test_management
    end
  end
end

# frozen_string_literal: true

module TestManagement
  module Suites
    class DeleteContract < ::DeleteContract
      delete_permission :manage_test_suites
    end
  end
end

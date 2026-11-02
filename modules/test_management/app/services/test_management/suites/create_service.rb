# frozen_string_literal: true

module TestManagement
  module Suites
    class CreateService < ::BaseServices::Create
      private

      def instance_class
        TestManagement::Suite
      end
    end
  end
end

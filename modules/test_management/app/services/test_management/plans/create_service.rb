# frozen_string_literal: true

module TestManagement
  module Plans
    class CreateService < ::BaseServices::Create
      private

      def instance_class
        TestManagement::TestPlan
      end
    end
  end
end

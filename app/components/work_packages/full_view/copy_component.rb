# frozen_string_literal: true

module WorkPackages
  module FullView
    class CopyComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(type:, copied_from_work_package_id:, project:)
        super

        @type = type
        @copied_from_work_package_id = copied_from_work_package_id
        @project = project
      end
    end
  end
end

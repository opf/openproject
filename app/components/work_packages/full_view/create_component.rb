# frozen_string_literal: true

module WorkPackages
  module FullView
    class CreateComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(type:, project:)
        super

        @type = type
        @project = project
      end
    end
  end
end

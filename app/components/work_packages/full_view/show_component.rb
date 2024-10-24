# frozen_string_literal: true

module WorkPackages
  module FullView
    class ShowComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def self.wrapper_key = :"work-package-full-view"

      def initialize(id:, tab: "activity")
        super

        @id = id
        @tab = tab
        @work_package = WorkPackage.visible.find_by(id:)
      end

      def wrapper_uniq_by
        @id
      end
    end
  end
end

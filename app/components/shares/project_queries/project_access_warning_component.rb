module Shares
  module ProjectQueries
    class ProjectAccessWarningComponent < ViewComponent::Base # rubocop:disable OpenProject/AddPreviewForViewComponent
      include OpPrimer::ComponentHelpers

      def initialize(strategy:, modal_body_container:)
        super

        @strategy = strategy
        @container = modal_body_container
      end

      private

      attr_reader :strategy, :container

      def query_is_public?
        @strategy.entity.public?
      end

      def query_is_shared?
        @strategy.entity.members.any?
      end
    end
  end
end

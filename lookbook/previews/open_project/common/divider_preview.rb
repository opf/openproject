module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class DividerPreview < Lookbook::Preview
      ##
      # **A simple divider (hr)**
      # ---------------------
      # Primer does not provide a HR component, so we rolled our own
      # default spacing is 4 top and bottom
      def default
        render OpenProject::Common::DividerComponent.new
      end

      # @param mt number
      # @param mb number
      def with_dynamic__margins(mt: 2, mb: 2) # rubocop:disable Naming/MethodParameterName
        render OpenProject::Common::DividerComponent.new(mt:, mb:)
      end
    end
  end
end

module OpenProject
  module Deprecated
    # @logical_path OpenProject/deprecated
    class SimpleFiltersPreview < Lookbook::Preview
      # Simple filters
      # --------------
      # Simple filters are forms that serve the purpose of limiting the number of entries in a list.
      # As opposed to advanced filters however, there is no operator selection to search with.
      #
      # By default, simple filters can have multiple fields per row (as many as the given space allows).
      def default; end

      def with_radio_buttons; end
    end
  end
end

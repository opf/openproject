module OpenProject
  module Deprecated
    # @logical_path OpenProject/deprecated
    class ToolbarComponentPreview < Lookbook::Preview
      # A toolbar that can and should be used for actions on the current view.
      # Initially designed for the Work package list, this can be reused throughout the application.
      def default; end

      def with_form_elements; end

      def with_labelled_form_elements; end
    end
  end
end

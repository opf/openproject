module OpenProject
  module Filter
    # @logical_path OpenProject/Filter
    class FilterButtonComponentPreview < Lookbook::Preview
      def default
        @query = ProjectQuery.new
        render(::Filter::FilterButtonComponent.new(query: @query))
      end

      # @label With toggable filter section
      # There is a stimulus controller, which can toggle the visibility of an FilterComponent with the help of a FilterButton.
      # Just register the controller in a container around both elements.
      # Unfortunately, stimulus controllers do not work in our lookbook as of now, so you will see no effect.
      def filter_section_toggle
        @query = ProjectQuery.new
        render_with_template(locals: { query: @query })
      end
    end
  end
end

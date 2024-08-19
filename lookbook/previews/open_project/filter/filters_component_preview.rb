module OpenProject
  module Filter
    # @logical_path OpenProject/Filter
    class FiltersComponentPreview < Lookbook::Preview
      def default
        @query = ProjectQuery.new
        render(Projects::ProjectsFiltersComponent.new(query: @query))
      end
    end
  end
end

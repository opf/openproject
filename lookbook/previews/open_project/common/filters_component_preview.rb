module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class FiltersComponentPreview < Lookbook::Preview
      def default
        @query = Queries::Projects::ProjectQuery.new
        render(Projects::ProjectsFiltersComponent.new(query: @query)) do |component|
          component.with_button(
            tag: :a,
            href: "",
            scheme: :primary,
            size: :medium,
            aria: { label: I18n.t(:label_project_new) },
            data: { "test-selector": "project-new-button" }
          ) do |button|
            button.with_leading_visual_icon(icon: :plus)
            Project.model_name.human
          end
        end
      end
    end
  end
end

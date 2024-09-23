module OpenProject::Queries
  # @logical_path OpenProject/Queries
  class SortByComponentPreview < Lookbook::Preview
    def default
      query = ::ProjectQuery.new
      query.order(lft: :asc)
      query.order(created_at: :desc)

      render ::Queries::SortByComponent.new(
        query:,
        selectable_columns: [
          { id: :lft, name: I18n.t(:label_project_hierarchy) },
          { id: :created_at, name: I18n.t("attributes.created_at") }
        ]
      )
    end
  end
end

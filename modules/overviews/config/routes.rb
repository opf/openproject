OpenProject::Application.routes.draw do
  constraints(project_id: Regexp.new("(?!(#{Project::RESERVED_IDENTIFIERS.join('|')})$)(\\w|-)+")) do
    get 'projects/:project_id', to: "overviews/overviews#show", as: :project_overview, format: :html
    get 'projects/:project_id/attributes_sidebar', to: "overviews/overviews#attributes_sidebar", as: :project_attributes_sidebar, format: :html
    get 'projects/:project_id/attribute_section_dialog', to: "overviews/overviews#attribute_section_dialog", as: :project_attribute_section_dialog, format: :html
    put 'projects/:project_id/attributes', to: "overviews/overviews#update_attributes", as: :project_update_attributes, format: :html
  end
end

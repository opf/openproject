OpenProject::Application.routes.draw do
  get 'projects/:project_id',
      to: "overviews/overviews#show",
      as: :project_overview,
      constraints: { format: :html, project_id: Regexp.new("(?!(#{Project::RESERVED_IDENTIFIERS.join('|')})$)(\\w|-)+") }
end

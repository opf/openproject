OpenProject::Application.routes.draw do
  scope '', as: 'backlogs' do
    scope 'projects/:project_id', as: 'project' do
      resources :boards, controller: 'boards/boards', only: :index
    end
  end
end

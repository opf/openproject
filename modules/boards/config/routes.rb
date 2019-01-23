OpenProject::Application.routes.draw do
  scope '', as: 'backlogs' do
    scope 'projects/:project_id', as: 'project' do
      get '/boards(/*state)', to: 'boards/boards#index'
    end
  end
end

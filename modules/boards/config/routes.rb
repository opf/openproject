OpenProject::Application.routes.draw do
  get '/boards/:id', to: 'boards/boards#index', as: 'board'

  scope '', as: 'boards' do
    scope 'projects/:project_id', as: 'project' do
      get '/boards(/*state)', to: 'boards/boards#index'
    end

    get '/boards(/*state)', to: 'boards/boards#index'
  end
end

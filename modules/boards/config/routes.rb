OpenProject::Application.routes.draw do
  scope '', as: :work_package_boards do
    get '/boards(/*state)', to: 'boards/boards#index'
  end

  scope 'projects/:project_id', as: 'project' do
    get '/boards(/*state)', to: 'boards/boards#index', as: :work_package_boards
  end
end

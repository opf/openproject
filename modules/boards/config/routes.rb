OpenProject::Application.routes.draw do
  get '/boards/all', to: 'boards/boards#overview'

  resources :boards,
            controller: 'boards/boards',
            only: %i[new create],
            as: :work_package_boards

  scope '', as: :work_package_boards do
    get '/boards(/*state)', to: 'boards/boards#index'
  end

  scope 'projects/:project_id', as: 'project' do
    resources :boards,
              controller: 'boards/boards',
              only: %i[new],
              as: :work_package_boards

    # Adding the `create` action into the above `resources` macro would
    # result in a name collision between it and `get /boards(/*state)`
    # as it would result in both being named `project_work_package_boards`
    post '/boards', to: 'boards/boards#create'
    get '/boards(/*state)', to: 'boards/boards#index', as: :work_package_boards
  end
end

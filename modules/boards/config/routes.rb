OpenProject::Application.routes.draw do
  get '/boards/all', to: 'boards/boards#overview'

  resources :boards,
            controller: 'boards/boards',
            only: %i[index show new create destroy],
            as: :work_package_boards

  scope 'projects/:project_id', as: 'project' do
    resources :boards,
              controller: 'boards/boards',
              only: %i[index new show],
              as: :work_package_boards

    # Adding the `create` action into the above `resources` macro would
    # result in a name collision between it and `get /boards(/*state)`
    # as it would result in both being named `project_work_package_boards`
    post '/boards', to: 'boards/boards#create'
  end
end

OpenProject::Application.routes.draw do
  get '/boards/all', to: 'boards/boards#overview'

  resources :boards,
            controller: 'boards/boards',
            only: %i[index show new create destroy],
            as: :work_package_boards

  scope 'projects/:project_id', as: 'project' do
    resources :boards,
              controller: 'boards/boards',
              only: %i[index show new create],
              as: :work_package_boards
  end
end

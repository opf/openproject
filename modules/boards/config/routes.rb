Rails.application.routes.draw do
  resources :boards,
            controller: 'boards/boards',
            only: %i[index new create destroy],
            as: :work_package_boards

  scope 'projects/:project_id', as: 'project' do
    resources :boards,
              controller: 'boards/boards',
              only: %i[index show new create],
              as: :work_package_boards do
      get '(/*state)' => 'boards/boards#show', on: :member, as: '', constraints: { id: /\d+/ }
    end
  end
end

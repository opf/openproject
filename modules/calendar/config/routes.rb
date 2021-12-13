OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :calendar, controller: 'calendar/calendar', only: [:index]
  end

  resources :calendar, controller: 'calendar/calendar', only: [:index]
end

OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    get '/calendar(/*state)', to: 'calendar/calendar#index', as: :index
  end

  get '/calendar(/*state)', to: 'calendar/calendar#index', as: :index
end

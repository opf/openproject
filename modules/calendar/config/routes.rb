OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :calendars,
              controller: 'calendar/calendars',
              only: %i[index destroy],
              as: :calendars do
      get '/' => 'calendar/calendars#show', on: :member, as: ''
      get '/new' => 'calendar/calendars#show', on: :collection, as: 'new'

      get '/split/:wp_id/' => 'calendar/calendars#details', on: :member, as: 'details'
      get '/split/:wp_id/overview' => 'calendar/calendars#overview', on: :member
      get '/split/:wp_id/relations' => 'calendar/calendars#relations', on: :member
    end
  end
end

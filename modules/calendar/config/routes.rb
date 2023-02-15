OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :calendars,
              controller: 'calendar/calendars',
              only: %i[index destroy],
              as: :calendars do
      get '/new' => 'calendar/calendars#show', on: :collection, as: 'new'
      # TODO: discuss if other controller should be used
      post '/generate_ical_url' => 'calendar/calendars#generate_ical_url', on: :member, as: 'generate_ical_url'
      # TODO: discuss if other controller should be used
      get '/ical' => 'calendar/calendars#ical', on: :member, as: 'ical'
      get '(/*state)' => 'calendar/calendars#show', on: :member, as: ''
    end
  end
end
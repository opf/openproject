Rails.application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :calendars,
              controller: 'calendar/calendars',
              only: %i[index destroy],
              as: :calendars do
      get '/new' => 'calendar/calendars#show', on: :collection, as: 'new'
      get '/ical' => 'calendar/ical#show', on: :member, as: 'ical'
      get '(/*state)' => 'calendar/calendars#show', on: :member, as: ''
    end
  end

  resources :calendars, only: %i[index new create], controller: 'calendar/calendars'
end

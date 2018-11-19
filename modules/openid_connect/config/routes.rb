Rails.application.routes.draw do
  get '/session/logout_warning', to: 'session#logout_warning'
end

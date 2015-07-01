require 'lobby_boy'

Rails.application.routes.draw do
  mount LobbyBoy::Engine, at: '/'

  get '/session/logout_warning', to: 'session#logout_warning'
end

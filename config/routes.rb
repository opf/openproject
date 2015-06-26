require 'lobby_boy'

Rails.application.routes.draw do
  mount LobbyBoy::Engine, at: '/'
end

LobbyBoy::Engine.routes.draw do
  get 'session/check'
  get 'session/state'
  get 'session/end'
  get 'session/refresh'
end

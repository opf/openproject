require 'omniauth'
require 'lobby_boy/omni_auth/failure_endpoint'

OmniAuth.config.on_failure = LobbyBoy::OmniAuth::FailureEndpoint

module LobbyBoy
  class Engine < ::Rails::Engine
    isolate_namespace LobbyBoy

    config.assets.precompile += %w( js.cookie-1.5.1.min.js )

    config.to_prepare do
      require 'lobby_boy/patches/session_management'
    end
  end
end

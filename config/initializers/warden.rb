require 'warden/strategies/global_basic_auth'
require 'warden/strategies/user_basic_auth'
require 'warden/strategies/session'

Warden::Strategies.add :global_basic_auth, Warden::Strategies::GlobalBasicAuth
Warden::Strategies.add :user_basic_auth, Warden::Strategies::UserBasicAuth
Warden::Strategies.add :session, Warden::Strategies::Session

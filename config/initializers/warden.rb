# Strategies provided by OpenProject:
require 'warden/strategies/basic_auth_failure'
require 'warden/strategies/global_basic_auth'
require 'warden/strategies/user_basic_auth'
require 'warden/strategies/session'

strategies = [
  [:basic_auth_failure, Warden::Strategies::BasicAuthFailure],
  [:global_basic_auth,  Warden::Strategies::GlobalBasicAuth],
  [:user_basic_auth,    Warden::Strategies::UserBasicAuth],
  [:session,            Warden::Strategies::Session]
]

strategies.each do |name, clazz|
  Warden::Strategies.add name, clazz
end

include OpenProject::Authentication::Scope

OpenProject::Authentication.update_strategies(API_V3) do |_strategies|
  [:global_basic_auth, :user_basic_auth, :basic_auth_failure, :session]
end

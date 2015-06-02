require 'open_project/authentication'

# Strategies provided by OpenProject:
require 'open_project/authentication/strategies/warden/basic_auth_failure'
require 'open_project/authentication/strategies/warden/global_basic_auth'
require 'open_project/authentication/strategies/warden/user_basic_auth'
require 'open_project/authentication/strategies/warden/session'

strategies = {
  basic_auth_failure: OpenProject::Authentication::Strategies::Warden::BasicAuthFailure,
  global_basic_auth:  OpenProject::Authentication::Strategies::Warden::GlobalBasicAuth,
  user_basic_auth:    OpenProject::Authentication::Strategies::Warden::UserBasicAuth,
  session:            OpenProject::Authentication::Strategies::Warden::Session
}

strategies.each do |name, clazz|
  Warden::Strategies.add name, clazz
end

include OpenProject::Authentication::Scope

OpenProject::Authentication.update_strategies(API_V3) do |_strategies|
  [:global_basic_auth, :user_basic_auth, :basic_auth_failure, :session]
end

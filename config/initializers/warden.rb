require 'open_project/authentication'

# Strategies provided by OpenProject:
require 'open_project/authentication/strategies/warden/basic_auth_failure'
require 'open_project/authentication/strategies/warden/global_basic_auth'
require 'open_project/authentication/strategies/warden/user_basic_auth'
require 'open_project/authentication/strategies/warden/session'

WS = OpenProject::Authentication::Strategies::Warden

strategies = [
  [:basic_auth_failure, WS::BasicAuthFailure, 'Basic'],
  [:global_basic_auth,  WS::GlobalBasicAuth,  'Basic'],
  [:user_basic_auth,    WS::UserBasicAuth,    'Basic'],
  [:session,            WS::Session,          'Session']
]

strategies.each do |name, clazz, auth_scheme|
  OpenProject::Authentication.add_strategy name, clazz, auth_scheme
end

include OpenProject::Authentication::Scope

api_v3_options = {
  store: false
}
OpenProject::Authentication.update_strategies(API_V3, api_v3_options) do |_strategies|
  [:global_basic_auth, :user_basic_auth, :basic_auth_failure, :session]
end

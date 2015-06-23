require 'open_project/authentication'

# Strategies provided by OpenProject:
require 'open_project/authentication/strategies/warden/basic_auth_failure'
require 'open_project/authentication/strategies/warden/global_basic_auth'
require 'open_project/authentication/strategies/warden/user_basic_auth'
require 'open_project/authentication/strategies/warden/session'

strategies = [
  [:basic_auth_failure, OpenProject::Authentication::Strategies::Warden::BasicAuthFailure, 'Basic'],
  [:global_basic_auth,  OpenProject::Authentication::Strategies::Warden::GlobalBasicAuth,  'Basic'],
  [:user_basic_auth,    OpenProject::Authentication::Strategies::Warden::UserBasicAuth,    'Basic'],
  [:session,            OpenProject::Authentication::Strategies::Warden::Session,          'Session']
]

strategies.each do |name, clazz, auth_scheme|
  OpenProject::Authentication.add_strategy name, clazz, auth_scheme
end

include OpenProject::Authentication::Scope

api_v3_options = {
  realm: 'OpenProject API'
}
OpenProject::Authentication.update_strategies(API_V3, api_v3_options) do |_strategies|
  [:global_basic_auth, :user_basic_auth, :basic_auth_failure, :session]
end

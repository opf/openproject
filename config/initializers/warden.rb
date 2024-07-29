Rails.application.config.after_initialize do
  namespace = OpenProject::Authentication::Strategies::Warden

  strategies = [
    [:basic_auth_failure, namespace::BasicAuthFailure,  "Basic"],
    [:global_basic_auth,  namespace::GlobalBasicAuth,   "Basic"],
    [:user_basic_auth,    namespace::UserBasicAuth,     "Basic"],
    [:oauth,              namespace::DoorkeeperOAuth,   "Bearer"],
    [:anonymous_fallback, namespace::AnonymousFallback, "Basic"],
    [:jwt_oidc,           namespace::JwtOidc,           "Bearer"],
    [:session,            namespace::Session,           "Session"]
  ]

  strategies.each do |name, clazz, auth_scheme|
    OpenProject::Authentication.add_strategy(name, clazz, auth_scheme)
  end

  OpenProject::Authentication.update_strategies(OpenProject::Authentication::Scope::API_V3, { store: false }) do |_|
    %i[global_basic_auth
       user_basic_auth
       basic_auth_failure
       oauth
       jwt_oidc
       session
       anonymous_fallback]
  end
end

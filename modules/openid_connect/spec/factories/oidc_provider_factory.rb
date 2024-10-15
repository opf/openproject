FactoryBot.define do
  factory :oidc_provider, class: "OpenIDConnect::Provider" do
    display_name { "Foobar" }
    slug { "oidc-foobar" }
    limit_self_registration { true }
    creator factory: :user

    options do
      {
        "issuer" => "https://keycloak.local/realms/master",
        "jwks_uri" => "https://keycloak.local/realms/master/protocol/openid-connect/certs",
        "client_id" => "https://openproject.local",
        "client_secret" => "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn",
        "oidc_provider" => "custom",
        "token_endpoint" => "https://keycloak.local/realms/master/protocol/openid-connect/token",
        "userinfo_endpoint" => "https://keycloak.local/realms/master/protocol/openid-connect/userinfo",
        "end_session_endpoint" => "https://keycloak.local/realms/master/protocol/openid-connect/logout",
        "authorization_endpoint" => "https://keycloak.local/realms/master/protocol/openid-connect/auth"
      }
    end
  end

  factory :oidc_provider_google, class: "OpenIDConnect::Provider" do
    display_name { "Google" }
    slug { "oidc-google" }
    limit_self_registration { true }
    creator factory: :user

    options do
      { "issuer" => "https://accounts.google.com",
        "jwks_uri" => "https://www.googleapis.com/oauth2/v3/certs",
        "client_id" => "identifier",
        "client_secret" => "secret",
        "oidc_provider" => "google",
        "token_endpoint" => "https://oauth2.googleapis.com/token",
        "userinfo_endpoint" => "https://openidconnect.googleapis.com/v1/userinfo",
        "authorization_endpoint" => "https://accounts.google.com/o/oauth2/v2/auth" }
    end
  end
end

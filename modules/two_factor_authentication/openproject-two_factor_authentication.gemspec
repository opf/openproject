Gem::Specification.new do |s|
  s.name        = "openproject-two_factor_authentication"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Two-factor authentication"
  s.description = "This OpenProject plugin authenticates your users using two-factor authentication by means of " \
                  "one-time password through the TOTP standard (Google Authenticator), WebAuthn or sent to the " \
                  "user's cell phone via SMS or voice call"

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]

  s.add_dependency "messagebird-rest", "~> 1.4.2"
  s.add_dependency "rotp", "~> 6.1"
  s.add_dependency "webauthn", "~> 3.0"

  s.add_dependency "aws-sdk-sns", "~> 1.82.0"
  s.metadata["rubygems_mfa_required"] = "true"
end

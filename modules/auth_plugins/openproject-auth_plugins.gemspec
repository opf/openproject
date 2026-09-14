Gem::Specification.new do |s|
  s.name        = "openproject-auth_plugins"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Auth Plugins"
  s.description = "Integration of OmniAuth strategy providers for authentication in OpenProject."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(doc/CHANGELOG.md README.md)

  s.add_dependency "omniauth", "~> 2.1"

  s.add_development_dependency "rspec", "~> 3.13"
  s.metadata["rubygems_mfa_required"] = "true"
end

Gem::Specification.new do |s|
  s.name        = "openproject-recaptcha"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject ReCaptcha"
  s.description = "This module provides recaptcha checks during login"

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]

  s.add_dependency "recaptcha", "~> 5.7"
  s.metadata["rubygems_mfa_required"] = "true"
end

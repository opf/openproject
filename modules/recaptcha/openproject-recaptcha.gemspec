# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-recaptcha"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/"
  s.summary     = "OpenProject ReCaptcha"
  s.description = "This module provides recaptcha checks during login"

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'recaptcha', '~> 5.5'
end

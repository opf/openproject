# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/two_factor_authentication/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-two_factor_authentication"
  s.version     = OpenProject::TwoFactorAuthentication::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/mobile-otp"
  s.summary     = "OpenProject Two-factor authentication"
  s.description = "This OpenProject plugin authenticates your users using two-factor authentication by means of one-time password " \
                  "through the TOTP standard (Google Authenticator) or sent to the user\'s cell phone via SMS or voice call"

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'rotp', '~> 3.3'
  s.add_dependency 'rails', '~> 5'
end

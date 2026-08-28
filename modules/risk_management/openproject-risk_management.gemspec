# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "openproject-risk_management"
  spec.version = "1.0.0"
  spec.authors = ["OpenProject contributors"]
  spec.email = ["info@openproject.com"]
  spec.homepage = "https://www.openproject.org/"
  spec.summary = "Risk management for OpenProject"
  spec.description = "Adds configurable risk management capabilities to OpenProject."
  spec.license = "GPLv3"
  spec.files = Dir["{app,config,lib}/**/*"] + %w[README.md]
  spec.metadata["rubygems_mfa_required"] = "true"
end

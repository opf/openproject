# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-llm"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject LLM connection"
  s.description = "Connects OpenProject to an LLM server and lets administrators choose the models AI features use"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "ruby_llm", "~> 1.16"
  s.metadata["rubygems_mfa_required"] = "true"
end

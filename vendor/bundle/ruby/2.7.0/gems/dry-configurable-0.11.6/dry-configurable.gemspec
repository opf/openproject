# frozen_string_literal: true
# this file is managed by dry-rb/devtools project

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/configurable/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-configurable'
  spec.authors       = ["Andy Holland"]
  spec.email         = ["andyholland1991@aol.com"]
  spec.license       = 'MIT'
  spec.version       = Dry::Configurable::VERSION.dup

  spec.summary       = "A mixin to add configuration functionality to your classes"
  spec.description   = spec.summary
  spec.homepage      = 'https://dry-rb.org/gems/dry-configurable'
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-configurable.gemspec", "lib/**/*"]
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['changelog_uri']     = 'https://github.com/dry-rb/dry-configurable/blob/master/CHANGELOG.md'
  spec.metadata['source_code_uri']   = 'https://github.com/dry-rb/dry-configurable'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/dry-rb/dry-configurable/issues'

  spec.required_ruby_version = ">= 2.4.0"

  # to update dependencies edit project.yml
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "dry-core", "~> 0.4", ">= 0.4.7"
  spec.add_runtime_dependency "dry-equalizer", "~> 0.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end

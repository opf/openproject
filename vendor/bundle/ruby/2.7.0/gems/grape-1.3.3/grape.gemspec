# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'grape/version'

Gem::Specification.new do |s|
  s.name        = 'grape'
  s.version     = Grape::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Michael Bleigh']
  s.email       = ['michael@intridea.com']
  s.homepage    = 'https://github.com/ruby-grape/grape'
  s.summary     = 'A simple Ruby framework for building REST-like APIs.'
  s.description = 'A Ruby framework for rapid API development with great conventions.'
  s.license     = 'MIT'
  s.metadata    = {
    'bug_tracker_uri'   => 'https://github.com/ruby-grape/grape/issues',
    'changelog_uri'     => "https://github.com/ruby-grape/grape/blob/v#{s.version}/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/grape/#{s.version}",
    'source_code_uri'   => "https://github.com/ruby-grape/grape/tree/v#{s.version}"
  }

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'builder'
  s.add_runtime_dependency 'dry-types', '>= 1.1'
  s.add_runtime_dependency 'mustermann-grape', '~> 1.0.0'
  s.add_runtime_dependency 'rack', '>= 1.3.0'
  s.add_runtime_dependency 'rack-accept'

  s.files         = %w[CHANGELOG.md CONTRIBUTING.md README.md grape.png UPGRADING.md LICENSE]
  s.files        += %w[grape.gemspec]
  s.files        += Dir['lib/**/*']
  s.test_files    = Dir['spec/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.4.0'
end

# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/core/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-core'
  spec.version       = Dry::Core::VERSION
  spec.authors       = ['Nikita Shilnikov']
  spec.email         = ['fg@flashgordon.ru']

  spec.summary       = 'A toolset of small support modules used throughout the dry-rb ecosystem.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/dry-rb/dry-core'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|bin)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.1.0'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'warden/basic_auth/version'

Gem::Specification.new do |spec|
  spec.name          = "warden-basic_auth"
  spec.version       = Warden::BasicAuth::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Finn GmbH"]
  spec.email         = ["info@finn.de"]

  spec.summary       = %q{Provides a base class for basic auth stragies.}
  spec.homepage      = "https://github.com/opf/warden-basic_auth"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "warden", "~> 1.2"

  spec.add_development_dependency "bundler", "~> 1.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10.1"
  spec.add_development_dependency "rspec", "~> 3.2"
end

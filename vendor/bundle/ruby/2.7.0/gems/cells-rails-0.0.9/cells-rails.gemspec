lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cells/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "cells-rails"
  spec.version       = Cells::Rails::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = %q{Convenient Rails support for Cells.}
  spec.homepage      = "http://trailblazer.to"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cells", ">= 4.1.6", "< 5.0.0"
  spec.add_dependency "actionpack", ">= 3.0"


  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "cells-erb"
  spec.add_development_dependency "sass-rails"
end

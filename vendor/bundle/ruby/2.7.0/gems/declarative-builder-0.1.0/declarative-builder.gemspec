require File.expand_path('../lib/declarative/builder/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nick Sutterer"]
  gem.email         = ["apotonick@gmail.com"]
  gem.description   = %q{Generic builder pattern.}
  gem.summary       = %q{Generic builder pattern.}
  gem.homepage      = "https://github.com/apotonick/declarative-builder"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "declarative-builder"
  gem.require_paths = ["lib"]
  gem.version       = Declarative::Builder::VERSION

  gem.add_dependency "declarative-option", "< 0.2.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
end

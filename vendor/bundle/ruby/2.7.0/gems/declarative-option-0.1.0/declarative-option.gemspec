require File.expand_path('../lib/declarative/option/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nick Sutterer"]
  gem.email         = ["apotonick@gmail.com"]
  gem.description   = %q{Dynamic options.}
  gem.summary       = %q{Dynamic options to evaluate at runtime.}
  gem.homepage      = "https://github.com/apotonick/declarative-option"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "declarative-option"
  gem.require_paths = ["lib"]
  gem.version       = Declarative::Option::VERSION

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
end

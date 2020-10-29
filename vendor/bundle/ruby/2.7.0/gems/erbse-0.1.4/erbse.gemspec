lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'erbse/version'

Gem::Specification.new do |spec|
  spec.name        = "erbse"
  spec.version     = Erbse::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Nick Sutterer"]
  spec.email       = ["apotonick@gmail.com"]
  spec.homepage    = "https://github.com/apotonick/erbse"
  spec.summary     = %q{Updated Erubis.}
  spec.description = %q{An updated Erubis with block support. Block inheritance soon to come.}
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "temple"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end

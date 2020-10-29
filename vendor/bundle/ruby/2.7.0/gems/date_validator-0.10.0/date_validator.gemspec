# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "date_validator/version"

Gem::Specification.new do |s|
  s.name        = "date_validator"
  s.version     = DateValidator::VERSION
  s.authors     = ["Oriol Gual", "Josep M. Bach", "Josep Jaume Rey"]
  s.email       = ["info@codegram.com"]
  s.homepage    = "http://github.com/codegram/date_validator"
  s.summary     = %q{A simple, ORM agnostic, Ruby 1.9 compatible date validator for Rails 3+, based on ActiveModel.}
  s.description = %q{A simple, ORM agnostic, Ruby 1.9 compatible date validator for Rails 3+, based on ActiveModel. Currently supporting :after, :before, :after_or_equal_to and :before_or_equal_to options.}

  s.rubyforge_project = "date_validator"

  s.add_runtime_dependency 'activemodel', '>= 3'
  s.add_runtime_dependency 'activesupport', '>= 3'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake', '>= 12.3.3'
  s.add_development_dependency 'tzinfo'

  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

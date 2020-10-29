# -*- encoding: utf-8 -*-
# stub: date_validator 0.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "date_validator".freeze
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Oriol Gual".freeze, "Josep M. Bach".freeze, "Josep Jaume Rey".freeze]
  s.date = "2020-04-03"
  s.description = "A simple, ORM agnostic, Ruby 1.9 compatible date validator for Rails 3+, based on ActiveModel. Currently supporting :after, :before, :after_or_equal_to and :before_or_equal_to options.".freeze
  s.email = ["info@codegram.com".freeze]
  s.homepage = "http://github.com/codegram/date_validator".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A simple, ORM agnostic, Ruby 1.9 compatible date validator for Rails 3+, based on ActiveModel.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activemodel>.freeze, [">= 3"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
    s.add_development_dependency(%q<tzinfo>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activemodel>.freeze, [">= 3"])
    s.add_dependency(%q<activesupport>.freeze, [">= 3"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 12.3.3"])
    s.add_dependency(%q<tzinfo>.freeze, [">= 0"])
  end
end

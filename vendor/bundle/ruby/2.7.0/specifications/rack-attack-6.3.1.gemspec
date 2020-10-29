# -*- encoding: utf-8 -*-
# stub: rack-attack 6.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-attack".freeze
  s.version = "6.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/kickstarter/rack-attack/issues", "changelog_uri" => "https://github.com/kickstarter/rack-attack/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/kickstarter/rack-attack" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aaron Suggs".freeze]
  s.date = "2020-05-21"
  s.description = "A rack middleware for throttling and blocking abusive requests".freeze
  s.email = "aaron@ktheory.com".freeze
  s.homepage = "https://github.com/kickstarter/rack-attack".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Block & throttle abusive requests".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1.0", "< 3"])
    s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.2"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.17", "< 3.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11"])
    s.add_development_dependency(%q<minitest-stub-const>.freeze, ["~> 0.6"])
    s.add_development_dependency(%q<rack-test>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["= 0.78.0"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.5.0"])
    s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9.1"])
    s.add_development_dependency(%q<byebug>.freeze, ["~> 11.0"])
    s.add_development_dependency(%q<railties>.freeze, [">= 4.2", "< 6.1"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 1.0", "< 3"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.2"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.17", "< 3.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.11"])
    s.add_dependency(%q<minitest-stub-const>.freeze, ["~> 0.6"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.78.0"])
    s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.5.0"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.9.1"])
    s.add_dependency(%q<byebug>.freeze, ["~> 11.0"])
    s.add_dependency(%q<railties>.freeze, [">= 4.2", "< 6.1"])
  end
end

# -*- encoding: utf-8 -*-
# stub: actionpack 6.0.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "actionpack".freeze
  s.version = "6.0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v6.0.3.4/actionpack/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v6.0.3.4/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "source_code_uri" => "https://github.com/rails/rails/tree/v6.0.3.4/actionpack" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2020-10-07"
  s.description = "Web apps on Rails. Simple, battle-tested conventions for building and testing MVC web applications. Works with any Rack-compatible server.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.requirements = ["none".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Web-flow and rendering framework putting the VC in MVC (part of Rails).".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<rack>.freeze, ["~> 2.0", ">= 2.0.8"])
    s.add_runtime_dependency(%q<rack-test>.freeze, [">= 0.6.3"])
    s.add_runtime_dependency(%q<rails-html-sanitizer>.freeze, ["~> 1.0", ">= 1.2.0"])
    s.add_runtime_dependency(%q<rails-dom-testing>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<actionview>.freeze, ["= 6.0.3.4"])
    s.add_development_dependency(%q<activemodel>.freeze, ["= 6.0.3.4"])
  else
    s.add_dependency(%q<activesupport>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<rack>.freeze, ["~> 2.0", ">= 2.0.8"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0.6.3"])
    s.add_dependency(%q<rails-html-sanitizer>.freeze, ["~> 1.0", ">= 1.2.0"])
    s.add_dependency(%q<rails-dom-testing>.freeze, ["~> 2.0"])
    s.add_dependency(%q<actionview>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<activemodel>.freeze, ["= 6.0.3.4"])
  end
end

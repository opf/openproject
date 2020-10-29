# -*- encoding: utf-8 -*-
# stub: dry-inflector 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-inflector".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-inflector/issues", "changelog_uri" => "https://github.com/dry-rb/dry-inflector/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-inflector" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze, "Andrii Savchenko".freeze, "Abinoam P. Marques Jr.".freeze]
  s.bindir = "exe".freeze
  s.date = "2019-10-13"
  s.description = "String inflections for dry-rb".freeze
  s.email = ["me@lucaguidi.com".freeze, "andrey@aejis.eu".freeze, "abinoam@gmail.com".freeze]
  s.homepage = "https://dry-rb.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "DRY Inflector".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.50.0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.50.0"])
  end
end

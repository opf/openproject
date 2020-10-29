# -*- encoding: utf-8 -*-
# stub: sanitize 5.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "sanitize".freeze
  s.version = "5.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2.0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Grove".freeze]
  s.date = "2020-06-16"
  s.description = "Sanitize is an allowlist-based HTML and CSS sanitizer. It removes all HTML and/or CSS from a string except the elements, attributes, and properties you choose to allow.".freeze
  s.email = "ryan@wonko.com".freeze
  s.homepage = "https://github.com/rgrove/sanitize/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Allowlist-based HTML and CSS sanitizer.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<crass>.freeze, ["~> 1.0.2"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.8.0"])
    s.add_runtime_dependency(%q<nokogumbo>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11.3"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.3.1"])
  else
    s.add_dependency(%q<crass>.freeze, ["~> 1.0.2"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.8.0"])
    s.add_dependency(%q<nokogumbo>.freeze, ["~> 2.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.11.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.3.1"])
  end
end

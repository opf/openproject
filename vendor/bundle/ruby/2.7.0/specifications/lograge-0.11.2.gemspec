# -*- encoding: utf-8 -*-
# stub: lograge 0.11.2 ruby lib

Gem::Specification.new do |s|
  s.name = "lograge".freeze
  s.version = "0.11.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mathias Meyer".freeze, "Ben Lovell".freeze]
  s.date = "2019-06-14"
  s.description = "Tame Rails' multi-line logging into a single line per request".freeze
  s.email = ["meyer@paperplanes.de".freeze, "benjamin.lovell@gmail.com".freeze]
  s.homepage = "https://github.com/roidrage/lograge".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Tame Rails' multi-line logging into a single line per request".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["= 0.46.0"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4"])
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 4"])
    s.add_runtime_dependency(%q<railties>.freeze, [">= 4"])
    s.add_runtime_dependency(%q<request_store>.freeze, ["~> 1.0"])
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.46.0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 4"])
    s.add_dependency(%q<actionpack>.freeze, [">= 4"])
    s.add_dependency(%q<railties>.freeze, [">= 4"])
    s.add_dependency(%q<request_store>.freeze, ["~> 1.0"])
  end
end

# -*- encoding: utf-8 -*-
# stub: warden 1.2.9 ruby lib

Gem::Specification.new do |s|
  s.name = "warden".freeze
  s.version = "1.2.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Neighman".freeze, "Justin Smestad".freeze, "Whitney Smestad".freeze, "Jos\u00E9 Valim".freeze]
  s.date = "2020-08-31"
  s.email = "hasox.sox@gmail.com justin.smestad@gmail.com whitcolorado@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/hassox/warden".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "An authentication library compatible with all Rack-based frameworks".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 2.0.9"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 2.0.9"])
  end
end

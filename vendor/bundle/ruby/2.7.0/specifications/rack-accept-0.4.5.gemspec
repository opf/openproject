# -*- encoding: utf-8 -*-
# stub: rack-accept 0.4.5 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-accept".freeze
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Jackson".freeze]
  s.date = "2012-06-15"
  s.description = "HTTP Accept, Accept-Charset, Accept-Encoding, and Accept-Language for Ruby/Rack".freeze
  s.email = "mjijackson@gmail.com".freeze
  s.extra_rdoc_files = ["CHANGES".freeze, "README.md".freeze]
  s.files = ["CHANGES".freeze, "README.md".freeze]
  s.homepage = "http://mjijackson.github.com/rack-accept".freeze
  s.rdoc_options = ["--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "Rack::Accept".freeze, "--main".freeze, "Rack::Accept".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "HTTP Accept* for Ruby/Rack".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 0.4"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 0.4"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end

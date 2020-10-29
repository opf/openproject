# -*- encoding: utf-8 -*-
# stub: validate_email 0.1.6 ruby lib

Gem::Specification.new do |s|
  s.name = "validate_email".freeze
  s.version = "0.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tanel Suurhans".freeze, "Tarmo Lehtpuu".freeze]
  s.date = "2012-07-12"
  s.description = "Library for validating email addresses in Rails 3 models.".freeze
  s.email = ["tanel.suurhans@perfectline.ee".freeze, "tarmo.lehtpuu@perfectline.ee".freeze]
  s.extra_rdoc_files = ["README.markdown".freeze]
  s.files = ["README.markdown".freeze]
  s.homepage = "http://github.com/perfectline/validates_email/tree/master".freeze
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Library for validating email addresses in Rails 3 models.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<diff-lcs>.freeze, [">= 1.1.2"])
    s.add_development_dependency(%q<active_record>.freeze, [">= 3.0.0"])
    s.add_development_dependency(%q<sqlite3-ruby>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<mail>.freeze, [">= 2.2.5"])
    s.add_runtime_dependency(%q<activemodel>.freeze, [">= 3.0"])
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<diff-lcs>.freeze, [">= 1.1.2"])
    s.add_dependency(%q<active_record>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<sqlite3-ruby>.freeze, [">= 0"])
    s.add_dependency(%q<mail>.freeze, [">= 2.2.5"])
    s.add_dependency(%q<activemodel>.freeze, [">= 3.0"])
  end
end

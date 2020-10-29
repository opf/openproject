# -*- encoding: utf-8 -*-
# stub: gravatar_image_tag 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gravatar_image_tag".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Deering".freeze]
  s.date = "2013-11-11"
  s.email = "mdeering@mdeering.com".freeze
  s.extra_rdoc_files = ["README.textile".freeze]
  s.files = ["README.textile".freeze]
  s.homepage = "http://github.com/mdeering/gravatar_image_tag".freeze
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A configurable and documented Rails view helper for adding gravatars into your Rails application.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<activesupport>.freeze, ["~> 3.2.0"])
    s.add_development_dependency(%q<actionpack>.freeze, ["~> 3.2.0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rb-fsevent>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<jeweler>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activesupport>.freeze, ["~> 3.2.0"])
    s.add_dependency(%q<actionpack>.freeze, ["~> 3.2.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<guard>.freeze, [">= 0"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rb-fsevent>.freeze, ["~> 0.9"])
    s.add_dependency(%q<jeweler>.freeze, [">= 0"])
  end
end

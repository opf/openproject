# -*- encoding: utf-8 -*-
# stub: browser 4.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "browser".freeze
  s.version = "4.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/fnando/browser/blob/master/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nando Vieira".freeze]
  s.date = "2020-05-31"
  s.description = "Do some browser detection with Ruby.".freeze
  s.email = ["fnando.vieira@gmail.com".freeze]
  s.homepage = "https://github.com/fnando/browser".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Do some browser detection with Ruby.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest-autotest>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest-utils>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry-meta>.freeze, [">= 0"])
    s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_development_dependency(%q<rails>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop-fnando>.freeze, ["~> 0.0.3"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-autotest>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-utils>.freeze, [">= 0"])
    s.add_dependency(%q<pry-meta>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop-fnando>.freeze, ["~> 0.0.3"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
  end
end

# -*- encoding: utf-8 -*-
# stub: escape_utils 1.2.1 ruby lib
# stub: ext/escape_utils/extconf.rb

Gem::Specification.new do |s|
  s.name = "escape_utils".freeze
  s.version = "1.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Lopez".freeze]
  s.date = "2016-04-13"
  s.description = "Quickly perform HTML, URL, URI and Javascript escaping/unescaping".freeze
  s.email = "seniorlopez@gmail.com".freeze
  s.extensions = ["ext/escape_utils/extconf.rb".freeze]
  s.files = ["ext/escape_utils/extconf.rb".freeze]
  s.homepage = "https://github.com/brianmario/escape_utils".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Faster string escaping routines for your web apps".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0.7.5"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 5.0.0"])
    s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_development_dependency(%q<rack>.freeze, [">= 0"])
    s.add_development_dependency(%q<haml>.freeze, [">= 0"])
    s.add_development_dependency(%q<fast_xs>.freeze, [">= 0"])
    s.add_development_dependency(%q<actionpack>.freeze, [">= 0"])
    s.add_development_dependency(%q<url_escape>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rake-compiler>.freeze, [">= 0.7.5"])
    s.add_dependency(%q<minitest>.freeze, [">= 5.0.0"])
    s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<haml>.freeze, [">= 0"])
    s.add_dependency(%q<fast_xs>.freeze, [">= 0"])
    s.add_dependency(%q<actionpack>.freeze, [">= 0"])
    s.add_dependency(%q<url_escape>.freeze, [">= 0"])
  end
end

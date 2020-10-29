# -*- encoding: utf-8 -*-
# stub: lobby_boy 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "lobby_boy".freeze
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Finn GmbH".freeze]
  s.date = "2018-07-09"
  s.email = ["info@finn.de".freeze]
  s.homepage = "https://github.com/finnlabs/lobby_boy".freeze
  s.licenses = ["GPLv3".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Rails engine for OpenIDConnect Session Management".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, [">= 3.2.21"])
    s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 1.1"])
    s.add_runtime_dependency(%q<omniauth-openid-connect>.freeze, [">= 0.2.1"])
  else
    s.add_dependency(%q<rails>.freeze, [">= 3.2.21"])
    s.add_dependency(%q<omniauth>.freeze, ["~> 1.1"])
    s.add_dependency(%q<omniauth-openid-connect>.freeze, [">= 0.2.1"])
  end
end

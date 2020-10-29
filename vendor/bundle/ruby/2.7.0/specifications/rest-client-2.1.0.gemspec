# -*- encoding: utf-8 -*-
# stub: rest-client 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rest-client".freeze
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["REST Client Team".freeze]
  s.date = "2019-08-21"
  s.description = "A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions: get, put, post, delete.".freeze
  s.email = "discuss@rest-client.groups.io".freeze
  s.executables = ["restclient".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "history.md".freeze]
  s.files = ["README.md".freeze, "bin/restclient".freeze, "history.md".freeze]
  s.homepage = "https://github.com/rest-client/rest-client".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Simple HTTP and REST client for Ruby, inspired by microframework syntax for specifying actions.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<webmock>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0"])
    s.add_development_dependency(%q<pry-doc>.freeze, ["~> 0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 2.4.2", "< 6.0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.49"])
    s.add_runtime_dependency(%q<http-accept>.freeze, [">= 1.7.0", "< 2.0"])
    s.add_runtime_dependency(%q<http-cookie>.freeze, [">= 1.0.2", "< 2.0"])
    s.add_runtime_dependency(%q<mime-types>.freeze, [">= 1.16", "< 4.0"])
    s.add_runtime_dependency(%q<netrc>.freeze, ["~> 0.8"])
  else
    s.add_dependency(%q<webmock>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<pry>.freeze, ["~> 0"])
    s.add_dependency(%q<pry-doc>.freeze, ["~> 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 2.4.2", "< 6.0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.49"])
    s.add_dependency(%q<http-accept>.freeze, [">= 1.7.0", "< 2.0"])
    s.add_dependency(%q<http-cookie>.freeze, [">= 1.0.2", "< 2.0"])
    s.add_dependency(%q<mime-types>.freeze, [">= 1.16", "< 4.0"])
    s.add_dependency(%q<netrc>.freeze, ["~> 0.8"])
  end
end

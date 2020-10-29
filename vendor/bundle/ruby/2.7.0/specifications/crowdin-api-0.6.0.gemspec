# -*- encoding: utf-8 -*-
# stub: crowdin-api 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "crowdin-api".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Crowdin".freeze]
  s.date = "2019-06-26"
  s.description = "Ruby Client for the Crowdin API".freeze
  s.email = ["support@crowdin.net".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/crowdin/crowdin-api/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Client library to manage translations on Crowdin".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rest-client>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.9"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8"])
    s.add_development_dependency(%q<webmock>.freeze, ["~> 3.6"])
    s.add_development_dependency(%q<sinatra>.freeze, ["~> 2.0", ">= 2.0.5"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 11.2", ">= 11.2.2"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.12.2"])
  else
    s.add_dependency(%q<rest-client>.freeze, ["~> 2.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.9"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.8"])
    s.add_dependency(%q<webmock>.freeze, ["~> 3.6"])
    s.add_dependency(%q<sinatra>.freeze, ["~> 2.0", ">= 2.0.5"])
    s.add_dependency(%q<rake>.freeze, ["~> 11.2", ">= 11.2.2"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.12.2"])
  end
end

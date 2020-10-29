# -*- encoding: utf-8 -*-
# stub: plaintext 0.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "plaintext".freeze
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jens Kr\u00E4mer".freeze, "Planio GmbH".freeze, "OpenProject GmbH".freeze]
  s.bindir = "exe".freeze
  s.date = "2019-10-01"
  s.description = "Extract text from common office files. Based on the file's content type a command line tool is selected to do the job.".freeze
  s.email = ["info@openproject.com".freeze]
  s.homepage = "https://github.com/planio-gmbh/plaintext".freeze
  s.licenses = ["GPL-2.0".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Extract plain text from most common office documents.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, ["> 2.2.1"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.10", ">= 1.10.4"])
    s.add_runtime_dependency(%q<rubyzip>.freeze, ["~> 1.3.0"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activesupport>.freeze, ["> 2.2.1"])
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.10", ">= 1.10.4"])
    s.add_dependency(%q<rubyzip>.freeze, ["~> 1.3.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end

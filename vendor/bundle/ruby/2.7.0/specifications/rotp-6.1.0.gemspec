# -*- encoding: utf-8 -*-
# stub: rotp 6.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rotp".freeze
  s.version = "6.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mark Percival".freeze]
  s.date = "2020-08-03"
  s.description = "Works for both HOTP and TOTP, and includes QR Code provisioning".freeze
  s.email = ["mark@markpercival.us".freeze]
  s.executables = ["rotp".freeze]
  s.files = ["bin/rotp".freeze]
  s.homepage = "http://github.com/mdp/rotp".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.3".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A Ruby library for generating and verifying one time passwords".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_development_dependency(%q<timecop>.freeze, ["~> 0.8"])
  else
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.8"])
  end
end

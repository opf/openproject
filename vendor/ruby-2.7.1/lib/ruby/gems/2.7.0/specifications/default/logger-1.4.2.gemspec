# -*- encoding: utf-8 -*-
# stub: logger 1.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "logger".freeze
  s.version = "1.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Naotoshi Seo".freeze, "SHIBATA Hiroshi".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-04-16"
  s.description = "Provides a simple logging utility for outputting messages.".freeze
  s.email = ["sonots@gmail.com".freeze, "hsbt@ruby-lang.org".freeze]
  s.files = ["logger.rb".freeze, "logger/errors.rb".freeze, "logger/formatter.rb".freeze, "logger/log_device.rb".freeze, "logger/period.rb".freeze, "logger/severity.rb".freeze, "logger/version.rb".freeze]
  s.homepage = "https://github.com/ruby/logger".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Provides a simple logging utility for outputting messages.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
  end
end

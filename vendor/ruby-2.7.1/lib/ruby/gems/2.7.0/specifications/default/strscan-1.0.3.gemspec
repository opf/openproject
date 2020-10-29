# -*- encoding: utf-8 -*-
# stub: strscan 1.0.3 ruby lib
# stub: ext/strscan/extconf.rb

Gem::Specification.new do |s|
  s.name = "strscan".freeze
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Minero Aoki".freeze, "Sutou Kouhei".freeze]
  s.date = "2020-04-16"
  s.description = "Provides lexical scanning operations on a String.".freeze
  s.email = [nil, "kou@cozmixng.org".freeze]
  s.extensions = ["ext/strscan/extconf.rb".freeze]
  s.files = ["ext/strscan/extconf.rb".freeze, "strscan.so".freeze]
  s.homepage = "https://github.com/ruby/strscan".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Provides lexical scanning operations on a String.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0"])
    s.add_development_dependency(%q<benchmark-driver>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rake-compiler>.freeze, [">= 0"])
    s.add_dependency(%q<benchmark-driver>.freeze, [">= 0"])
  end
end

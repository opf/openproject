# -*- encoding: utf-8 -*-
# stub: readline 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "readline".freeze
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["aycabta".freeze]
  s.date = "2020-04-16"
  s.description = "This is just a loader for \"readline\". If Ruby has \"readline-ext\" gem that\nis a native extension, this gem will load it first. If Ruby doesn't have\nthe \"readline-ext\" gem this gem will load \"reline\" that is a compatible\nlibrary with \"readline-ext\" gem and is implemented by pure Ruby.\n".freeze
  s.email = ["aycabta@gmail.com".freeze]
  s.files = ["readline.rb".freeze]
  s.homepage = "https://github.com/ruby/readline".freeze
  s.licenses = ["Ruby license".freeze]
  s.post_install_message = "+---------------------------------------------------------------------------+\n| This is just a loader for \"readline\". If Ruby has \"readline-ext\" gem that |\n| is a native extension, this gem will load it first. If Ruby doesn't have  |\n| the \"readline-ext\" gem this gem will load \"reline\" that is a compatible \u00A0 |\n| library with \"readline-ext\" gem and is implemented by pure Ruby. \u00A0 \u00A0 \u00A0 \u00A0 \u00A0|\n| \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 |\n| If you intend to use GNU Readline by `require 'readline'`, please install |\n| \"readline-ext\" gem. \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 \u00A0 |\n+---------------------------------------------------------------------------+\n".freeze
  s.rubygems_version = "3.1.2".freeze
  s.summary = "It's a loader for \"readline\".".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<reline>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<reline>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end

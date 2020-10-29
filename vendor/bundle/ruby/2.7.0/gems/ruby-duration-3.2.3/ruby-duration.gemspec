# -*- encoding: utf-8 -*-
require File.expand_path("../lib/duration/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "ruby-duration"
  s.version     = Duration::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jose Peleteiro", "Bruno Azisaka Maciel"]
  s.email       = ["jose@peleteiro.net", "bruno@azisaka.com.br"]
  s.homepage    = "http://github.com/peleteiro/ruby-duration"
  s.summary     = "Duration type"
  s.description = "Duration type"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "ruby-duration"


  s.add_dependency "activesupport", ">= 3.0.0"
  s.add_dependency "i18n", ">= 0"
  s.add_dependency "iso8601", ">= 0"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "minitest", ">= 0"
  s.add_development_dependency "yard", ">= 0"
  # Yard doesn't support Rake 11 currently.
  s.add_development_dependency "rake", "< 11.0"
  s.add_development_dependency "simplecov", ">= 0.3.5"
  s.add_development_dependency "mongoid", ">= 3.0.0", "< 4.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'

  s.rdoc_options = ["--charset=UTF-8"]
end

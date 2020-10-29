# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "auto_strip_attributes/version"

Gem::Specification.new do |s|
  s.name        = "auto_strip_attributes"
  s.version     = AutoStripAttributes::VERSION
  s.authors     = ["Olli Huotari"]
  s.email       = ["olli.huotari@iki.fi"]
  s.homepage    = "https://github.com/holli/auto_strip_attributes"
  s.summary     = "Removes unnecessary whitespaces in attributes. Extension to ActiveRecord or ActiveModel."
  s.description = "AutoStripAttributes helps to remove unnecessary whitespaces from ActiveRecord or ActiveModel attributes. It's good for removing accidental spaces from user inputs. It works by adding a before_validation hook to the record. It has option to set empty strings to nil or to remove extra spaces inside the string."
  s.license     = "MIT"

  s.rubyforge_project = "auto_strip_attributes"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  s.add_runtime_dependency "activerecord", ">= 4.0"

  #s.add_development_dependency "activerecord", ">= 3.0"
  s.add_development_dependency "minitest", ">= 2.8.1"
  s.add_development_dependency "mocha", "~> 0.14"
  s.add_development_dependency 'rake'
  # s.add_development_dependency 'pry'

end

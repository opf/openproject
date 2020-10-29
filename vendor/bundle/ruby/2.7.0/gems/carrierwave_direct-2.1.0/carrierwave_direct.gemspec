# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "carrierwave_direct/version"

Gem::Specification.new do |s|
  s.name        = "carrierwave_direct"
  s.version     = CarrierwaveDirect::VERSION
  s.authors     = ["David Wilkie"]
  s.email       = ["dwilkie@gmail.com"]
  s.homepage    = "https://github.com/dwilkie/carrierwave_direct"
  s.summary     = %q{Upload direct to S3 using CarrierWave}
  s.description = %q{Process your uploads in the background by uploading directly to S3}
  s.required_ruby_version = ">= 2.0.0"

  s.rubyforge_project = "carrierwave_direct"

  s.add_dependency "carrierwave", '>= 1.0.0'
  s.add_dependency "fog-aws"

  s.add_development_dependency "rspec", '~> 3.0'
  s.add_development_dependency "timecop"
  s.add_development_dependency "rails", ">= 3.2.12"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "capybara"
  s.add_development_dependency "byebug"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

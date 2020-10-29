# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed_cron_job/version'

Gem::Specification.new do |spec|
  spec.name          = "delayed_cron_job"
  spec.version       = DelayedCronJob::VERSION
  spec.authors       = ["Pascal Zumkehr"]
  spec.email         = ["spam@codez.ch"]
  spec.summary       = %q{An extension to Delayed::Job that allows you to set
                          cron expressions for your jobs to run regularly.}
  spec.description   = %q{Delayed Cron Job is an extension to Delayed::Job
                          that allows you to set cron expressions for your
                          jobs to run regularly.}
  spec.homepage      = "https://github.com/codez/delayed_cron_job"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "delayed_job", ">= 4.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "delayed_job_active_record"
  spec.add_development_dependency "activejob"

end

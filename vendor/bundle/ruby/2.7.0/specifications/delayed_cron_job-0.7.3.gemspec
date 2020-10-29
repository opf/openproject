# -*- encoding: utf-8 -*-
# stub: delayed_cron_job 0.7.3 ruby lib

Gem::Specification.new do |s|
  s.name = "delayed_cron_job".freeze
  s.version = "0.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pascal Zumkehr".freeze]
  s.date = "2020-06-25"
  s.description = "Delayed Cron Job is an extension to Delayed::Job\n                          that allows you to set cron expressions for your\n                          jobs to run regularly.".freeze
  s.email = ["spam@codez.ch".freeze]
  s.homepage = "https://github.com/codez/delayed_cron_job".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "An extension to Delayed::Job that allows you to set cron expressions for your jobs to run regularly.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<delayed_job>.freeze, [">= 4.1"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_development_dependency(%q<delayed_job_active_record>.freeze, [">= 0"])
    s.add_development_dependency(%q<activejob>.freeze, [">= 0"])
  else
    s.add_dependency(%q<delayed_job>.freeze, [">= 4.1"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<delayed_job_active_record>.freeze, [">= 0"])
    s.add_dependency(%q<activejob>.freeze, [">= 0"])
  end
end

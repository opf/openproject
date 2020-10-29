# -*- encoding: utf-8 -*-
# stub: delayed_job 4.1.8 ruby lib

Gem::Specification.new do |s|
  s.name = "delayed_job".freeze
  s.version = "4.1.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brandon Keepers".freeze, "Brian Ryckbost".freeze, "Chris Gaffney".freeze, "David Genord II".freeze, "Erik Michaels-Ober".freeze, "Matt Griffin".freeze, "Steve Richert".freeze, "Tobias L\u00FCtke".freeze]
  s.date = "2019-08-16"
  s.description = "Delayed_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background. It is a direct extraction from Shopify where the job table is responsible for a multitude of core tasks.".freeze
  s.email = ["brian@collectiveidea.com".freeze]
  s.homepage = "http://github.com/collectiveidea/delayed_job".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Database-backed asynchronous priority queue system -- Extracted from Shopify".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0", "< 6.1"])
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 3.0", "< 6.1"])
  end
end

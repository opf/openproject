# -*- encoding: utf-8 -*-
# stub: airbrake-ruby 5.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "airbrake-ruby".freeze
  s.version = "5.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Airbrake Technologies, Inc.".freeze]
  s.date = "2020-08-18"
  s.description = "Airbrake Ruby is a plain Ruby notifier for Airbrake (https://airbrake.io), the\nleading exception reporting service. Airbrake Ruby provides minimalist API that\nenables the ability to send any Ruby exception to the Airbrake dashboard. The\nlibrary is extremely lightweight and it perfectly suits plain Ruby applications.\nFor apps that are built with Rails, Sinatra or any other Rack-compliant web\nframework we offer the airbrake gem (https://github.com/airbrake/airbrake). It\nhas additional features such as reporting of any unhandled exceptions\nautomatically, integrations with Resque, Sidekiq, Delayed Job and many more.\n".freeze
  s.email = "support@airbrake.io".freeze
  s.homepage = "https://airbrake.io".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Ruby notifier for https://airbrake.io".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rbtree3>.freeze, ["~> 0.5"])
  else
    s.add_dependency(%q<rbtree3>.freeze, ["~> 0.5"])
  end
end

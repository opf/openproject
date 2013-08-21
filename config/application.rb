#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../boot', __FILE__)

require 'benchmark'
module SimpleBenchmark
  #
  # Measure execution of block and display result
  #
  # Time is measured by Benchmark module, displayed time is total
  # (user cpu time + system cpu time + user and system cpu time of children)
  # This is not wallclock time.
  def self.bench(title)
    print "#{title}... "
    result = Benchmark.measure do
      yield
    end
    print "%.03fs\n" % result.total
  end
end

SimpleBenchmark.bench "require 'rails/all'" do
  require 'rails/all'
end

if defined?(Bundler)
  SimpleBenchmark.bench 'Bundler.require' do
    Bundler.require(:default, :assets, :opf_plugins, Rails.env)
  end
end

module OpenProject
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths << Rails.root.join('lib')

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = :journal_observer, :message_observer, :issue_observer,
                                     :news_observer, :wiki_content_observer,
                                     :comment_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # automatically compile translations.js
    config.middleware.use I18n::JS::Middleware

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Load any local configuration that is kept out of source control
    # (e.g. patches).
    if File.exists?(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
      instance_eval File.read(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
    end

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = false

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # initialize variable for register plugin tests
    config.plugins_to_test_paths = []

    config.to_prepare do
      # Rails loads app/views paths of all plugin on each request and appends it to the view_paths.
      # Thus, they end up behind the core view path and core views are found before plugin views.
      # To change this behaviour, we just reverse the view_path order on each request so plugin views
      # take precedence.
      ApplicationController.view_paths = ActionView::PathSet.new(ApplicationController.view_paths.to_ary.reverse)
      ActionMailer::Base.view_paths = ActionView::PathSet.new(ActionMailer::Base.view_paths.to_ary.reverse)
    end
  end
end

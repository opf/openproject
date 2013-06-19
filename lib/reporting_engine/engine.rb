require 'rails/engine'

module ReportingEngine
  class Engine < ::Rails::Engine
    engine_name :reportingengine

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer 'reportingengine.precompile_assets' do
      Rails.application.config.assets.precompile += %w(reporting_engine.css reporting_engine.js)
    end

    initializer 'check mysql version' do
      connection = ActiveRecord::Base.connection
      adapter_name = connection.adapter_name.to_s.downcase.to_sym
      if [:mysql, :mysql2].include?(adapter_name)
        mysql_version = connection.show_variable("VERSION")
        if  mysql_version.start_with?("5.6")
          # The reporting engine is not compatible with mysql version 5.6
          # due to a bug in MySQL itself.
          # see https://www.openproject.org/issues/967 for details.
          raise "MySQL 5.6 is not yet supported."
        end
      end
    end

    config.to_prepare do
      require 'reporting_engine/patches'
      require 'reporting_engine/patches/big_decimal_patch'
      require 'reporting_engine/patches/to_date_patch'
      #We have to require this here because Ruby will otherwise find Date
      #as Object::Date and Rails wont autoload Widget::Filters::Date
      require_dependency 'widget/filters/date'
    end

    config.after_initialize do
      Redmine::Plugin.register :reportingengine do
        name 'ReportingEngine'
        author 'Finn GmbH'
        description 'A plugin to support creating reports'

        url 'https://www.openproject.org/projects/plugin-reportingengine/'
        author_url 'http://www.finn.de/'

        version ReportingEngine::VERSION
      end
    end
  end
end

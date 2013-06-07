require 'rails/engine'

module ReportingEngine
  class Engine < ::Rails::Engine
    engine_name :reportingengine

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer 'reportingengine.precompile_assets' do
      Rails.application.config.assets.precompile += %w(reporting_engine.css reporting_engine.js)
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
        description 'A plugin for reports'

        url 'https://github.com/finnlabs/reportingengine'
        author_url 'http://www.finn.de/'

        version ReportingEngine::VERSION
      end
    end
  end
end

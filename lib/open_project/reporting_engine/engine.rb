require 'rails/engine'

module OpenProject::ReportingEngine
  class Engine < ::Rails::Engine
    engine_name :openproject_reportingengine

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer 'reportingengine.precompile_assets' do
      Rails.application.config.assets.precompile += %w(reportingengine.css reportingengine.js)
    end


    config.to_prepare do
      require_dependency 'open_project/reporting_engine/patches'
      require_dependency 'open_project/reporting_engine/patches/big_decimal_patch'
      require_dependency 'open_project/reporting_engine/patches/to_date_patch'
    end

    config.after_initialize do
      Redmine::Plugin.register :openproject_reportingengine do
        name 'OpenProject ReportingEngine'
        author 'Finn GmbH'
        description 'A plugin for reports'

        url 'https://github.com/finnlabs/openproject_reportingengine'
        author_url 'http://www.finn.de/'

        version OpenProject::ReportingEngine::VERSION
      end
    end
  end
end

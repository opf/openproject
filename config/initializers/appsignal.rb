require 'open_project/version'
require_relative '../../lib_static/open_project/appsignal'

if OpenProject::Appsignal.enabled?
  require 'appsignal'
  OpenProject::Application.configure do |app|
    config = {
      active: true,
      name: ENV.fetch('APPSIGNAL_NAME'),
      push_api_key: ENV.fetch('APPSIGNAL_KEY'),
      revision: OpenProject::VERSION.to_s,
      ignore_actions: %w[OkComputerController#index OkComputerController#show]
    }

    if ENV['APPSIGNAL_DEBUG'] == 'true'
      config[:log] = 'stdout'
      config[:debug] = true
      config[:log_level] = 'debug'
    end

    Appsignal.config = Appsignal::Config.new(
      Rails.root,
      Rails.env,
      config
    )

    app.middleware.insert_after(
      ActionDispatch::DebugExceptions,
      Appsignal::Rack::RailsInstrumentation
    )

    Appsignal.start
  end
end

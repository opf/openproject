require 'open_project/version'
require_relative '../../lib_static/open_project/appsignal'

if OpenProject::Appsignal.enabled?
  require 'appsignal'
  Rails.application.configure do |app|
    config = {
      active: true,
      name: ENV.fetch('APPSIGNAL_NAME'),
      push_api_key: ENV.fetch('APPSIGNAL_KEY'),
      revision: OpenProject::VERSION.to_s,
      ignore_actions: [
        'OkComputer::OkComputerController#show',
        'OkComputer::OkComputerController#index',
        'GET::API::V3::Notifications::NotificationsAPI',
        'GET::API::V3::Notifications::NotificationsAPI#/notifications/'
      ],
      ignore_errors: [
        'Grape::Exceptions::MethodNotAllowed',
        'ActionController::UnknownFormat',
        'ActiveJob::DeserializationError',
        'Net::SMTPServerBusy'
      ]
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

    # Extend the core log delegator
    handler = OpenProject::Appsignal.method(:exception_handler)
    OpenProject::Logging::LogDelegator.register(:appsignal, handler)

    Appsignal.start
  end
end

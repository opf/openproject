module OkComputer
  class OkComputerController < ActionController::Base
    include LegacyRailsControllerSupport if Rails::VERSION::MAJOR < 5

    layout nil

    before_action :authenticate

    if OkComputer.analytics_ignore && defined?(NewRelic::Agent::Instrumentation::ControllerInstrumentation)
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      newrelic_ignore if respond_to?(:newrelic_ignore)
    end

    rescue_from OkComputer::Registry::CheckNotFound do |e|
      respond_to do |f|
        f.any(:text, :html) { render plain: e.message, status: :not_found, content_type: 'text/plain' }
        f.json { render json: { error: e.message }, status: :not_found }
      end
    end

    def index
      checks = OkComputer::Registry.all
      checks.run

      respond checks, status_code(checks)
    end

    def show
      check = OkComputer::Registry.fetch(params[:check])
      check.run

      respond check, status_code(check)
    end

  private

    def respond(data, status)
      respond_to do |format|
         format.any(:text, :html) { render plain: data, status: status, content_type: 'text/plain' }
         format.json { render json: data, status: status }
      end
    end

    def status_code(check)
      check.success? ? :ok : :internal_server_error
    end

    def authenticate
      if OkComputer.requires_authentication?(params)
        authenticate_or_request_with_http_basic do |username, password|
          OkComputer.authenticate(username, password)
        end
      end
    end
  end
end

class OpenProject::RoutedExceptions::SelectivePublic < ActionDispatch::PublicExceptions
  def call(env)
    if routed_error?(env)
      OpenProject::Application.routes.call env
    else
      super
    end
  end

  private

  def routed_error?(env)
    routed_errors.include?(status(env))
  end

  def status(env)
    env['PATH_INFO'][1..-1]
  end

  def routed_errors
    Rails.application.config.routed_exceptions.in_app_errors
  end
end

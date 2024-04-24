module NoRoutingErrorLogging
  def log_error(env, wrapper)
    super unless ignore_error?(env, wrapper)
  end

  def ignore_error?(env, wrapper)
    !Rails.logger.debug? && routing_error?(env, wrapper)
  end

  def routing_error?(_env, wrapper)
    wrapper.exception.is_a? ActionController::RoutingError
  end
end

ActionDispatch::DebugExceptions.prepend NoRoutingErrorLogging if Rails.env.production?

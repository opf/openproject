class OpenProject::RoutedExceptions::SelectiveDebug < ActionDispatch::DebugExceptions
  def log_error(env, wrapper)
    exception = wrapper.exception

    super unless logging_disabled?(exception)
  end

  private

  def logging_disabled?(exception)
    disabled_exceptions.any? do |klass|
      exception.is_a?(klass)
    end
  end

  def disabled_exceptions
    [AbstractController::ActionNotFound,
     ActionController::RoutingError]
  end
end

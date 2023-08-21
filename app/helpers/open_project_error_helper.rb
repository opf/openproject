##
# Logging helper to forward to the OpenProject log delegator
# which will log and report errors appropriately.
module OpenProjectErrorHelper
  def op_logger
    ::OpenProject.logger
  end

  def op_handle_error(message_or_exception, context = {})
    ::OpenProject.logger.error message_or_exception, context.merge(op_logging_context)
  end

  def op_handle_warning(message_or_exception, context = {})
    ::OpenProject.logger.warn message_or_exception, context.merge(op_logging_context)
  end

  def op_handle_info(message_or_exception, context = {})
    ::OpenProject.logger.info message_or_exception, context.merge(op_logging_context)
  end

  def op_handle_debug(message_or_exception, context = {})
    ::OpenProject.logger.debug message_or_exception, context.merge(op_logging_context)
  end

  private

  def op_logging_context
    {
      current_user: User.current,
      params: try(:params),
      request: try(:request),
      session: try(:session),
      env: try(:env)
    }
  end
end

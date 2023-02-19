module Rack
  class Timeout
    module SuppressInternalErrorReportOnTimeout
      def op_handle_error(message_or_exception, context = {})
        return if respond_to?(:request) && request.env[Rack::Timeout::ENV_INFO_KEY].try(:state) == :timed_out

        super
      end
    end
  end
end

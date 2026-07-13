# frozen_string_literal: true

# Possible events related to job-iteration.
# https://github.com/Shopify/job-iteration/blob/main/guides/best-practices.md#instrumentation
# build_enumerator.iteration
# throttled.iteration (when using ThrottleEnumerator)
# nil_enumerator.iteration
# resumed.iteration
# each_iteration.iteration
# not_found.iteration
# interrupted.iteration
# completed.iteration

ActiveSupport::Notifications.monotonic_subscribe("each_iteration.iteration") do |_, started, finished, _, tags|
  elapsed = finished - started

  max_iteration_runtime = 3.minutes
  if elapsed >= max_iteration_runtime
    Rails.logger.warn "[Iteration] job_class=#{tags[:job_class]} " \
                      "each_iteration runtime exceeded limit of #{max_iteration_runtime}s"
  end
end

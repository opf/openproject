# frozen_string_literal: true

module Storages
  class HealthStatusMailerJob < ApplicationJob
    def perform(storage)
      if storage.healthy?
        return
      end

      Storages::StoragesMailer.notify_unhealthy(storage).deliver_now

      reschedule
    end

    private

    def reschedule
      next_run_time = Date.now.tomorrow.beginning_of_the_day + 2.hours

      self.class.set(wait_until: next_run_time).perform_later
    end
  end
end

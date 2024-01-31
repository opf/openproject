module Storages
  module Health
    class HealthService
      def initialize(storage:)
        @storage = storage
      end

      def healthy
        was_unhealthy = @storage.health_unhealthy?

        @storage.mark_as_healthy

        ::Storages::StoragesMailer.notify_healthy(@storage).deliver_now if was_unhealthy
      end

      def unhealthy(reason:)
        @storage.mark_as_unhealthy(reason:)

        ::Storages::StoragesMailer.notify_unhealthy(@storage, reason).deliver_now

        schedule_mail_job unless mail_job_exists?
      end

      private

      def schedule_mail_job
        ::Storages::HealthStatusMailerJob.schedule
      end

      def mail_job_exists?
        Delayed::Job.where('handler LIKE ?', "%job_class: Storages::HealthStatusMailerJob%").any?
      end
    end
  end
end

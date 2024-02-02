module Storages
  module Health
    class HealthService
      def initialize(storage:)
        @storage = storage
      end

      def healthy
        was_unhealthy = @storage.health_unhealthy?

        @storage.mark_as_healthy

        admin_users.each do |admin|
          ::Storages::StoragesMailer.notify_healthy(admin, @storage).deliver_now if was_unhealthy
        end
      end

      def unhealthy(reason:)
        @storage.mark_as_unhealthy(reason:)

        admin_users.each do |admin|
          ::Storages::StoragesMailer.notify_unhealthy(admin, @storage).deliver_now
        end

        schedule_mail_job(@storage) unless mail_job_exists?
      end

      private

      def admin_users
        User.where(admin: true)
            .where.not(mail: [nil, ''])
      end

      def schedule_mail_job(storage)
        ::Storages::HealthStatusMailerJob.schedule(admins: admin_users, storage:)
      end

      def mail_job_exists?
        Delayed::Job.where('handler LIKE ?', "%job_class: Storages::HealthStatusMailerJob%").any?
      end
    end
  end
end

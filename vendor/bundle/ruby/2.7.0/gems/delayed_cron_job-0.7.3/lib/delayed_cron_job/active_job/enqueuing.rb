module DelayedCronJob
  module ActiveJob
    module Enqueuing

      def self.included(klass)
        klass.send(:attr_accessor, :cron)
      end

      def enqueue(options = {})
        self.cron = options[:cron] if options[:cron]
        super
      end

    end
  end
end
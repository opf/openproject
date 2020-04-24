module Delayed
  class Job
    class Status < ApplicationRecord
      self.table_name = 'delayed_job_statuses'

      belongs_to :reference, polymorphic: true
      belongs_to :job, class_name: '::Delayed::Job'

      enum status: { in_queue: 0,
                     in_process: 1,
                     error: 2,
                     success: 3,
                     failure: 4 }

      def self.of_reference(reference)
        where(reference: reference)
      end
    end
  end
end
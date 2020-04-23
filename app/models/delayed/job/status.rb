module Delayed
  class Job
    class Status < ApplicationRecord
      self.table_name = 'delayed_job_statuses'

      belongs_to :reference, polymorphic: true
      belongs_to :job, class_name: '::Delayed::Job'

      enum status: { in_queue: 'in_queue',
                     error: 'error',
                     in_process: 'in_process',
                     success: 'success',
                     failure: 'failure' }

      def self.of_reference(reference)
        where(reference: reference)
      end
    end
  end
end
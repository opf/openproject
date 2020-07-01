module JobStatus
  class Status < ApplicationRecord
    self.table_name = 'delayed_job_statuses'

    belongs_to :user
    belongs_to :reference, polymorphic: true

    enum status: {
      in_queue: 'in_queue',
      error: 'error',
      in_process: 'in_process',
      success: 'success',
      failure: 'failure',
      cancelled: 'cancelled'
    }

    def self.of_reference(reference)
      where(reference: reference)
    end
  end
end

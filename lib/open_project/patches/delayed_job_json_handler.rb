require 'open_project/patches'

module OpenProject::Patches::DelayedJobJsonHandler
  extend ActiveSupport::Concern

  included do
    # Overwriting the methods for (de)serializing the handler.
    # That way, the handler is stored as json which is queryable performantly.
    def payload_object=(object)
      @payload_object = object
      self.handler = object.job_data
    end

    def payload_object
      @payload_object ||= ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(handler)
    end
  end
end

OpenProject::Patches.patch_gem_version 'delayed_job_active_record', '4.1.6' do
  Delayed::Backend::ActiveRecord::Job.include OpenProject::Patches::DelayedJobJsonHandler
end

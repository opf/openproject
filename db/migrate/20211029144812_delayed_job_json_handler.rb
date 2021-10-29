class DelayedJobJsonHandler < ActiveRecord::Migration[6.1]
  def up
    rename_column :delayed_jobs, :handler, :yaml_handler
    add_column :delayed_jobs, :handler, :jsonb

    Delayed::Job.find_each do |job|
      job.handler = YAML
                      .safe_load(job.yaml_handler,
                                 permitted_classes: [ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper])
                      .job_data
      job.save
    end

    add_index :delayed_jobs,
              "((delayed_jobs.handler->>'job_class'))",
              name: :index_delayed_jobs_job_class

    remove_column :delayed_jobs, :yaml_handler
  end

  def down
    rename_column :delayed_jobs, :handler, :json_handler
    add_column :delayed_jobs, :handler, :text

    Delayed::Job.find_each do |job|
      job.handler = YAML.dump(ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job.json_handler))
      job.save
    end

    remove_column :delayed_jobs, :json_handler
  end
end

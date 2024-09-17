#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class RemoveDelayedJobs < ActiveRecord::Migration[7.1]
  # it is needed, because ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
  # can not be used without required delayed_job
  # See https://github.com/rails/rails/blob/6f0d1ad14b92b9f5906e44740fce8b4f1c7075dc/activejob/lib/active_job/queue_adapters/delayed_job_adapter.rb
  class JobWrapperDeserializationMock
    attr_accessor :job_data

    def initialize(job_data)
      @job_data = job_data
    end
  end

  def change
    reversible do |direction|
      direction.up do
        tuples = execute <<~SQL
          select * from delayed_jobs
            where locked_by is null -- not in progress
            and handler NOT LIKE '%job_class: Storages::ManageNextcloudIntegrationEventsJob%' -- no need to migrate. It will be run later with cron.
            and cron is null -- not cron schedule
            FOR UPDATE; -- to prevent potentialy running delayed_job process working on these jobs(delayed_job uses SELECT FOR UPDATE to get workable jobs)
        SQL
        tuples.each do |tuple|
          handler = tuple["handler"].gsub("ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper",
                                          "ruby/object:#{RemoveDelayedJobs::JobWrapperDeserializationMock.name}")
          job_data = YAML.load(handler, permitted_classes: [RemoveDelayedJobs::JobWrapperDeserializationMock])
                         .job_data
          new_uuid = SecureRandom.uuid
          good_job_record = GoodJob::BaseExecution.new
          good_job_record.id = new_uuid
          good_job_record.serialized_params = job_data
          good_job_record.serialized_params["job_id"] = new_uuid
          good_job_record.queue_name = job_data["queue_name"]
          good_job_record.priority = job_data["priority"]
          good_job_record.scheduled_at = job_data["scheduled_at"]
          good_job_record.active_job_id = new_uuid
          good_job_record.concurrency_key = nil
          good_job_record.job_class = job_data["job_class"]
          good_job_record.save!
        end
      end
      direction.down {}
    end

    drop_table :delayed_jobs do |t|
      t.integer :priority, default: 0
      t.integer :attempts, default: 0
      t.text :handler
      t.text :last_error
      t.datetime :run_at
      t.datetime :locked_at
      t.datetime :failed_at
      t.string :locked_by
      t.timestamps null: true
      t.string :queue
      t.string :cron

      t.index %i[priority run_at], name: "delayed_jobs_priority"
    end
  end
end

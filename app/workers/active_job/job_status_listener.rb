#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module ActiveJob
  class JobStatusListener
    class << self
      def register!
        # Listen to enqueues
        ActiveSupport::Notifications.subscribe(/enqueue(_at)?\.active_job/) do |_name, job:, **_args|
          create_job_status(job) unless job.store_status?
        end

        # Start of process
        ActiveSupport::Notifications.subscribe('perform_start.active_job') do |job:, **_args|
          on_start(job) unless job.store_status?
        end

        # Complete, or failure
        ActiveSupport::Notifications.subscribe('perform.active_job') do |job:, exception_object: nil, **_args|
          on_performed(job, exception_object) unless job.store_status?
        end

        # Retry stopped -> failure
        ActiveSupport::Notifications.subscribe('retry_stopped.active_job') do |job:, error: nil, **_args|
          on_performed(job, error) unless job.store_status?
        end

        # Retry enqueued
        ActiveSupport::Notifications.subscribe('enqueue_retry.active_job') do |job, error: nil, **_args|
          on_requeue(job, error) unless job.store_status?
        end

        # Discarded job
        ActiveSupport::Notifications.subscribe('discard.active_job') do |job:, error: nil, **_args|
          on_cancelled(job, error) unless job.store_status?
        end
      end

      private

      ##
      # Create a status object when enqueuing a
      # new job through activejob that stores statuses
      def create_job_status(job)
        Delayed::Job::Status.create status: :in_queue,
                                    reference: job.status_reference,
                                    user: User.current,
                                    job_id: job.job_id
      end

      ##
      # On start processing a new job
      def on_start(job)
        update_status job, code: :in_process
      end

      ##
      # On requeuing a job after error
      def on_requeue(job, error)
        update_status job,
                      code: :in_queue,
                      message: I18n.t('background_jobs.status.error_requeue', message: error)
      end

      ##
      # On cancellation due to the given error
      def on_cancelled(job, error)
        update_status job,
                      code: :cancelled,
                      message: I18n.t('background_jobs.status.cancelled_due_to', message: error)
      end

      ##
      # On job performed, update status
      def on_performed(job, exception_object)
        if exception_object
          update_status job,
                        code: :failure,
                        message: exception_object.to_s
        else
          update_status job, code: :success
        end
      end

      ##
      # Update the status code for a given job
      def update_status(job, code:, message: nil)
        Delayed::Job::Status
          .where(job_id: job.job_id)
          .update_all(status: code, message: message)
      end
    end
  end
end

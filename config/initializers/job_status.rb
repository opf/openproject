#-- encoding: UTF-8

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

# Extends the ActiveJob adapter in use (DelayedJob) by a Status which lives
# indenpendently from the job itself (which is deleted once successful or after max attempts).
# That way, the result of a background job is available even after the original job is gone.

ActiveSupport::Notifications.subscribe "perform.active_job" do |job:, exception_object: nil, **_args|
  next unless job.status_reference

  # job.provider_job_id is not filled at this point as
  # the ActiveJob adapter for DelayedJob is only setting it
  # on enqueue and enqueue_at.
  if exception_object
    dj_job_attempts = Delayed::Job.where(id: Delayed::Job::Status.of_reference(job.status_reference).select(:job_id))
                      .pluck(:attempts)
                      .first || 1

    new_status = if dj_job_attempts + 1 >= Delayed::Worker.max_attempts
                   :failure
                 else
                   :error
                 end

    Delayed::Job::Status
      .of_reference(job.status_reference)
      .update(status: new_status,
              message: exception_object)
  else
    Delayed::Job::Status
      .of_reference(job.status_reference)
      .update(status: :success)
  end
end

ActiveSupport::Notifications.subscribe "enqueue.active_job" do |job:, **_args|
  if job.status_reference
    Delayed::Job::Status.create(status: :in_queue,
                                reference: job.status_reference,
                                job_id: job.provider_job_id)
  end
end

ActiveSupport::Notifications.subscribe "enqueue_at.active_job" do |job:, **_args|
  if job.status_reference
    Delayed::Job::Status.create(status: :in_queue,
                                reference: job.status_reference,
                                job_id: job.provider_job_id)
  end
end

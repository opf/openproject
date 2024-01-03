#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# Disable delayed_job's own logging as we have activejob
Delayed::Worker.logger = nil

# By default bypass worker queue and execute asynchronous tasks at once
Delayed::Worker.delay_jobs = true

# Prevent loading ApplicationJob during initialization
Rails.application.reloader.to_prepare do
  # Set default priority (lower = higher priority)
  # Example ordering, see ApplicationJob.priority_number
  Delayed::Worker.default_priority = ::ApplicationJob.priority_number(:default)
end

# Do not retry jobs from delayed_job
# instead use 'retry_on' activejob functionality
Delayed::Worker.max_attempts = 1

# Remember DJ id in the payload object
class Delayed::ProviderJobIdPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |job|
      job.payload_object.job_data['provider_job_id'] = job.id if job.payload_object.respond_to?(:job_data)
    end
  end
end

Delayed::Worker.plugins << Delayed::ProviderJobIdPlugin

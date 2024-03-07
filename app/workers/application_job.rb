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

require 'active_job'

class ApplicationJob < ActiveJob::Base
  include ::JobStatus::ApplicationJobWithStatus

  ##
  # By default, do not log the arguments of a background job
  # to avoid leaking sensitive information to logs
  self.log_arguments = false

  around_perform :prepare_job_context

  ##
  # Return a priority number on the given payload
  def self.priority_number(prio = :default)
    case prio
    when :high
      0
    when :notification
      5
    when :above_normal
      7
    when :below_normal
      13
    when :low
      20
    else
      10
    end
  end

  def self.queue_with_priority(value = :default)
    if value.is_a?(Symbol)
      super(priority_number(value))
    else
      super(value)
    end
  end

  # Resets the thread local request store.
  # This should be done, because normal application code expects the RequestStore to be
  # invalidated between multiple requests and does usually not care whether it is executed
  # from a request or from a delayed job.
  # For a delayed job, each job execution is the thing that comes closest to
  # the concept of a new request.
  def with_clean_request_store
    store = RequestStore.store

    begin
      RequestStore.clear!
      yield
    ensure
      # Reset to previous value
      RequestStore.clear!
      RequestStore.store.merge! store
    end
  end

  # Reloads the thread local ActionMailer configuration.
  # Since the email configuration is now done in the web app, we need to
  # make sure that any changes to the configuration is correctly picked up
  # by the background jobs at runtime.
  def reload_mailer_settings!
    Setting.reload_mailer_settings!
  end

  private

  def prepare_job_context
    with_clean_request_store do
      ::OpenProject::Appsignal.tag_request
      reload_mailer_settings!

      yield
    end
  end
end

# frozen_string_literal: true

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

# Shared setup for jobs.
#
# This module is included in `ApplicationJob` and `Mails::MailerJob` and does
# the following:
#
#   - disable logging of arguments
#   - before each job execution:
#     - reloads the mailer settings
#     - resets the request store
#     - tags the request for AppSignal
module SharedJobSetup
  extend ActiveSupport::Concern

  included do
    # By default, do not log the arguments of a background job
    # to avoid leaking sensitive information to logs
    self.log_arguments = false

    around_perform :prepare_job_context
  end

  # Prepare the job execution by cleaning the request store, reloading the
  # mailer settings and tagging the request
  def prepare_job_context
    with_clean_request_store do
      ::OpenProject::Appsignal.tag_request
      reload_mailer_settings!

      yield
    end
  end

  # Resets the thread local request store.
  #
  # This should be done, because normal application code expects the
  # RequestStore to be invalidated between multiple requests and does usually
  # not care whether it is executed from a request or from a job.
  #
  # For a job, each job execution is the thing that comes closest to the concept
  # of a new request.
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
  #
  # Since the email configuration is done in the web app, it makes sure that any
  # changes to the configuration is correctly picked up by the background jobs
  # at runtime.
  def reload_mailer_settings!
    Setting.reload_mailer_settings!
  end
end

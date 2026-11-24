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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  # Logging for the Jira import jobs. Include it in every job, after JobIteration::Iteration: it picks its
  # callbacks when included.
  #
  # Each run is wrapped in the job's context tags (log_context), so every line logged during the run carries them.
  # The concern logs "<Job> started" and "<Job> finished" at INFO, and "<Job> failed: <message>" at ERROR, once,
  # in the innermost log context.
  #
  # In a job:
  # - Declare what it imports: self.jira_object_type = "user".
  # - Wrap work on a single item in with_log_context with that item's tags, so every line about it carries them,
  #   e.g. with_log_context(jira_issue_key:) or with_log_context(jira_object_type: "user", jira_object_id_or_name:).
  # - Override log_context when the job's arguments differ from (jira_import_id, jira_project_id).
  # - Don't log an error before raising it. Inside perform / each_iteration, rescue only to recover
  #   (e.g. to skip a record that no longer exists). A job that rescues errors only to move the import into an error
  #   state does so in rescue_from.
  #
  # Log levels:
  # - DEBUG: every single object.
  # - INFO: status updates, such as a job or project starting or finishing.
  # - WARN: data not found or skipped, or data changed, while the import continues.
  # - ERROR: whatever makes the import fail. Raise it and the concern logs it.
  module JiraJobLogging
    extend ActiveSupport::Concern

    included do
      include GoodJob::ActiveJobExtensions::Batches

      class_attribute :jira_object_type, instance_accessor: false

      around_perform :with_job_log_context

      if include?(JobIteration::Iteration)
        # Not using job-iteration's on_start because it is skipped on retries. Also, don't log a second start
        # when before_perform is run when an interrupted job resumes.
        before_perform :log_started, unless: :resuming_after_interruption?
        on_complete :log_finished
      else
        before_perform :log_started
        after_perform :log_finished
      end
    end

    private

    def with_log_context(context)
      tags = context.compact.map { |key, value| "#{key}:#{value}" }
      logger.tagged(*tags) do
        yield
      rescue StandardError => e
        log_failed(e)
        raise
      end
    end

    def with_job_log_context(&)
      with_log_context(log_context, &)
    end

    def log_context
      project_key = Import::JiraProject.find(arguments.second).payload["key"] if arguments.second

      {
        batch_id: batch&.id,
        jira_import_id: arguments.first,
        jira_project_id: project_key,
        jira_object_type: self.class.jira_object_type
      }
    end

    def resuming_after_interruption?
      times_interrupted.positive?
    end

    def log_started
      logger.info "#{job_name} started"
    end

    def log_finished
      logger.info "#{job_name} finished"
    end

    def log_failed(error)
      return if @logged_failure.equal?(error)

      @logged_failure = error
      logger.error "#{job_name} failed: #{error.message}"
    end

    def job_name
      self.class.name.demodulize
    end
  end
end

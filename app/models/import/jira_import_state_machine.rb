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

module Import
  class JiraImportStateMachine
    include Statesman::Machine

    ### Order of states matters, because in other places we rely on it
    ### through Import::JiraImportStateMachine.states
    state :initial, initial: true
    state :instance_meta_fetching
    state :instance_meta_error
    state :instance_meta_done

    state :import_scope
    state :configuring
    state :projects_meta_fetching
    state :projects_meta_error
    state :projects_meta_done

    state :importing
    state :import_error
    state :import_aborting
    state :imported

    state :reverting
    state :revert_error
    state :reverted

    state :finalizing
    state :finalizing_error
    state :finalizing_done

    transition from: INITIAL,                to: [INSTANCE_META_FETCHING]
    transition from: INSTANCE_META_FETCHING, to: [INSTANCE_META_DONE, INSTANCE_META_ERROR]
    transition from: INSTANCE_META_ERROR,    to: [INSTANCE_META_FETCHING]
    transition from: INSTANCE_META_DONE,     to: [CONFIGURING, INSTANCE_META_FETCHING]
    transition from: CONFIGURING,            to: [PROJECTS_META_FETCHING]
    transition from: PROJECTS_META_FETCHING, to: [PROJECTS_META_DONE, PROJECTS_META_ERROR]
    transition from: PROJECTS_META_ERROR,    to: [PROJECTS_META_FETCHING]
    transition from: PROJECTS_META_DONE,     to: [IMPORTING]
    transition from: IMPORTING,              to: [IMPORTED, IMPORT_ERROR, IMPORT_ABORTING]
    transition from: IMPORT_ABORTING,        to: [IMPORT_ERROR]
    transition from: IMPORT_ERROR,           to: [IMPORTING, REVERTING]
    transition from: IMPORTED,               to: [FINALIZING, REVERTING]
    transition from: FINALIZING,             to: [FINALIZING_ERROR, FINALIZING_DONE]
    transition from: FINALIZING_ERROR,       to: [FINALIZING]
    transition from: REVERTING,              to: [REVERTED, REVERT_ERROR]
    transition from: REVERT_ERROR,           to: [REVERTING]

    def self.enqueued_job_id(job_class, jira_import_id)
      job = job_class.perform_later(jira_import_id)
      return job.job_id if job

      # GoodJob's enqueue_limit makes perform_later return false when an equivalent job is still queued
      GoodJob::Job
        .where(concurrency_key: job_class.new(jira_import_id).good_job_concurrency_key)
        .unfinished
        .order(:created_at)
        .pick(:id)
    end

    after_transition(to: :instance_meta_fetching) do |jira_import, transition|
      transition.metadata["job_id"] = enqueued_job_id(Import::JiraInstanceMetaDataJob, jira_import.id)
      transition.save!
    end

    after_transition(to: :projects_meta_fetching) do |jira_import, transition|
      transition.metadata["job_id"] = enqueued_job_id(Import::JiraProjectsMetaDataJob, jira_import.id)
      transition.metadata["user_id"] = User.current.id
      transition.save!
    end

    after_transition(to: :importing) do |jira_import, transition|
      last_importing_transition =
        jira_import
          .transitions
          .where(to_state: "importing", most_recent: false)
          .order(created_at: :desc)
          .first

      if last_importing_transition.nil?
        batch = GoodJob::Batch.enqueue(on_finish: Import::JiraStagedImportJob,
                                       jira_import_id: jira_import.id,
                                       stage: nil)
      else
        batch = last_importing_transition.actual_batch
        batch.retry
      end
      transition.metadata["batch_id"] = batch.id
      transition.metadata["user_id"] = User.current.id
      transition.save!
    end

    after_transition(to: :reverting) do |jira_import, transition|
      transition.metadata["job_id"] = enqueued_job_id(Import::JiraRevertImportJob, jira_import.id)
      transition.metadata["user_id"] = User.current.id
      transition.save!
    end

    after_transition(to: :finalizing) do |jira_import, transition|
      transition.metadata["job_id"] = enqueued_job_id(Import::JiraFinalizeImportJob, jira_import.id)
      transition.metadata["user_id"] = User.current.id
      transition.save!
    end

    after_transition(to: :import_aborting) do |jira_import, _transition|
      jira_import
        .state_machine
        .last_transition_to(:importing)
        .actual_batch
        ._record
        .jobs.each do |job|
        job.discard_job("Discarded because user clicked abort.") if job.status.in?(%i[queued retried scheduled])
      rescue GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError,
             GoodJob::Job::ActionForStateMismatchError
        next
      end
    end

    def state_equal_or_after?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) >= JiraImportStateMachine.states.index(check_status.to_s)
    end

    def state_equal_or_before?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) <= JiraImportStateMachine.states.index(check_status.to_s)
    end

    def state_before?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) < JiraImportStateMachine.states.index(check_status.to_s)
    end

    def state_after?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) > JiraImportStateMachine.states.index(check_status.to_s)
    end

    def running?
      [
        INSTANCE_META_FETCHING,
        PROJECTS_META_FETCHING,
        IMPORTING,
        IMPORT_ABORTING,
        REVERTING,
        FINALIZING
      ].include?(current_state)
    end

    def error?
      [
        INSTANCE_META_ERROR,
        PROJECTS_META_ERROR,
        IMPORT_ERROR,
        REVERT_ERROR,
        FINALIZING_ERROR
      ].include?(current_state)
    end

    def deletable?
      !running? && !in_state?(IMPORTED, IMPORT_ERROR, REVERT_ERROR)
    end
  end
end

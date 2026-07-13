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
    state :imported

    state :reverting
    state :revert_error
    state :revert_cancelling
    state :revert_cancelled
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
    transition from: IMPORTING,              to: [IMPORTED, IMPORT_ERROR]
    transition from: IMPORT_ERROR,           to: [IMPORTING, REVERTING]
    transition from: IMPORTED,               to: [FINALIZING, REVERTING]
    transition from: FINALIZING,             to: [FINALIZING_ERROR, FINALIZING_DONE]
    transition from: FINALIZING_ERROR,       to: [FINALIZING]
    transition from: REVERTING,              to: [REVERTED, REVERT_CANCELLING, REVERT_ERROR]
    transition from: REVERT_CANCELLING,      to: [REVERT_CANCELLED]
    transition from: REVERT_CANCELLED,       to: [REVERTING]
    transition from: REVERT_ERROR,           to: [REVERTING]

    after_transition(to: :reverted) do |jira_import, _transition|
      jira_import.update_column(:cursor, nil)
    end

    after_transition(to: :instance_meta_fetching) do |jira_import, _transition|
      Import::JiraInstanceMetaDataJob.perform_later(jira_import.id)
    end

    after_transition(to: :projects_meta_fetching) do |jira_import, _transition|
      Import::JiraProjectsMetaDataJob.perform_later(jira_import.id)
    end

    after_transition(to: :importing) do |jira_import, _transition|
      Import::JiraFetchAndImportProjectsJob.perform_later(jira_import.id)
    end

    after_transition(to: :reverting) do |jira_import, transition|
      job = Import::JiraRevertImportJob.perform_later(jira_import.id)
      transition.metadata["job_id"] = job.job_id
      transition.save!
    end

    after_transition(to: :finalizing) do |jira_import, _transition|
      Import::JiraFinalizeImportJob.perform_later(jira_import.id)
    end

    def status_running?
      [
        INSTANCE_META_FETCHING,
        PROJECTS_META_FETCHING,
        IMPORTING,
        REVERTING,
        REVERT_CANCELLING,
        FINALIZING
      ].include?(current_state)
    end

    def status_equal_or_after?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) >= JiraImportStateMachine.states.index(check_status.to_s)
    end

    def status_equal_or_before?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) <= JiraImportStateMachine.states.index(check_status.to_s)
    end

    def status_before?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) < JiraImportStateMachine.states.index(check_status.to_s)
    end

    def status_after?(check_status)
      JiraImportStateMachine.states.index(current_state.to_s) > JiraImportStateMachine.states.index(check_status.to_s)
    end

    def deletable?
      !status_running? && !in_state?(IMPORTED, IMPORT_ERROR, REVERT_ERROR)
    end
  end
end

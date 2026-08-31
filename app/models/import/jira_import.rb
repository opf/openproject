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
  class JiraImport < ApplicationRecord
    include Import::JiraOpenProjectReferenceCreation

    self.table_name = "jira_imports"

    belongs_to :jira, class_name: "Import::Jira"
    belongs_to :author, class_name: "User"

    has_many :transitions,
             class_name: "Import::JiraImportTransition",
             autosave: false,
             dependent: :destroy

    has_many :job_cursors,
             class_name: "Import::JiraImportJobCursor",
             dependent: :destroy

    def state_machine
      Import::JiraImportStateMachine.new(
        self,
        transition_class: Import::JiraImportTransition,
        association_name: :transitions
      )
    end

    delegate :can_transition_to?,
             :current_state,
             :history,
             :last_transition,
             :last_transition_to,
             :transition_to!,
             :transition_to,
             :in_state?,
             :running?,
             :state_equal_or_after?,
             :state_equal_or_before?,
             :state_after?,
             :state_before?,
             :deletable?,
             to: :state_machine

    delegate :client, to: :jira

    def project_ids
      (projects || []).pluck("id")
    end

    def destroy_jira_objects
      Import::JiraField.where(jira_import_id: id).destroy_all
      Import::JiraIssue.where(jira_import_id: id).destroy_all
      Import::JiraIssueType.where(jira_import_id: id).destroy_all
      Import::JiraPriority.where(jira_import_id: id).destroy_all
      Import::JiraProject.where(jira_import_id: id).destroy_all
      Import::JiraStatus.where(jira_import_id: id).destroy_all
      Import::JiraUser.where(jira_import_id: id).destroy_all
    end

    def set_job_cursor(job, cursor)
      Import::JiraImportJobCursor.upsert(
        {
          jira_import_id: id,
          job_class: job.class.to_s,
          arguments: job.arguments,
          cursor: cursor
        },
        unique_by: %i[jira_import_id job_class arguments]
      )
    end

    def get_job_cursor(active_job)
      job_cursors
        .where(job_class: active_job.class.to_s)
        .where("arguments = ?::jsonb",
               active_job.serialize["arguments"].to_json)
        .pick(:cursor)
    end
  end
end

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class JiraFinalizeImportJob < ApplicationJob
    def perform(jira_import_id)
      jira_import = Import::JiraImport.find(jira_import_id)

      unlock_active_jira_users(jira_import)
      jira_import.destroy_jira_objects
      jira_import.transition_to!(:finalizing_done)
    rescue StandardError => e
      jira_import&.transition_to!(:finalizing_error, error: e.message)
      jira_import&.update!(job_id: nil, error: e.message)
    end

    private

    def unlock_active_jira_users(jira_import)
      Import::JiraOpenProjectReference
        .where(
          jira_import_id: jira_import.id,
          jira_entity_class: "Import::JiraUser",
          uses_existing: false
        )
        .find_each do |ref|
          jira_user = ref.jira_leg
          next unless jira_user.payload["active"]

          op_user = ref.op_leg
          Journal::NotificationConfiguration.with(false) do
            Journal::EventConfiguration.with(false) do
              Users::UpdateService
                .new(model: op_user, user: User.system, contract_class: Users::JiraImportUpdateContract)
                .call(status: :active)
                .on_failure { |result| raise result.message }
            end
          end
        end
    end
  end
end

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
  class JiraCreateWorkflowTransitionsJob < ApplicationJob
    include Import::JiraJobUtils

    def text
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title")
    end

    def perform(jira_import_id)
      tagged_log("jira_import_id:#{jira_import_id}", "jira_object_type:workflow") do
        Rails.logger.debug "Creating workflow transitions started"
        role = Role.find_by!(name: "JiraMember")
        workflows_of_imported_types(jira_import_id).each do |workflow|
          OpenProject::Mutex.with_advisory_lock_transaction(workflow) { JiraWorkflowTransitions.allow_all(role, workflow) }
        end
        Rails.logger.debug "Creating workflow transitions finished"
      end
    end

    private

    # TODO: needs to be adjusted in JIM-336 to operate on the variant
    def workflows_of_imported_types(jira_import_id)
      type_ids = JiraOpenProjectReference
                   .where(jira_import_id:, op_entity_class: Type.name)
                   .select("op_entity_id::bigint")
      Workflow.where(id: TypeVariant.default_variant.where(type_id: type_ids).select(:workflow_id))
    end
  end
end

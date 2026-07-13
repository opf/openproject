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
  module JiraOpenProjectReferenceCreation
    private

    def create_reference!(op_leg:, jira_leg:, jira_import:, uses_existing:)
      Import::JiraOpenProjectReference.upsert_all(
        [
          { op_entity_id: op_leg.id,
            op_entity_class: op_leg.class.to_s,
            jira_entity_id: jira_leg&.id,
            jira_entity_class: jira_leg&.class&.to_s,
            jira_import_id: jira_import.id,
            jira_id: jira_import.jira.id,
            uses_existing: }
        ],
        unique_by: %i[op_entity_id op_entity_class jira_id]
      )
    end
  end
end

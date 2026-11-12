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

module ProjectCustomFieldProjectMappings
  class DeleteService < ::BaseServices::Delete
    protected

    def after_perform(service_result)
      super.tap do
        recalculate_values(service_result)
      end
    end

    def recalculate_values(service_result)
      mapping = service_result.result
      project = mapping.project

      affected_cfs = project.all_available_custom_fields.affected_calculated_fields([mapping.custom_field_id])

      project.calculate_custom_fields(affected_cfs)

      project.save if project.changed_for_autosave?
    end

    # Mappings have custom deletion rules that are similar to the update rules all derived from the base contract
    # Reuse the update contract to ensure that the deletion rules are consistent with the update rules
    def default_contract_class
      ProjectCustomFieldProjectMappings::UpdateContract
    end
  end
end

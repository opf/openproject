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
module BasicData
  class WorkflowSeeder < ModelSeeder
    self.needs = [
      BasicData::ProjectRoleSeeder,
      BasicData::GlobalRoleSeeder,
      BasicData::StatusSeeder,
      BasicData::TypeSeeder
    ]
    self.model_class = Workflow
    self.seed_data_model_key = "workflows"
    self.attribute_names_for_required_references = %w[statuses type]

    def seed_data!
      seed_workflows
    end

    private

    def seed_workflows
      member = seed_data.find_reference(:default_role_member)
      project_admin = seed_data.find_reference(:default_role_project_admin)
      work_package_editor = seed_data.find_reference(:default_role_work_package_editor)

      # Workflows belong to a type's base variant (the configuration in force by default).
      workflows.each do |type_variant, statuses|
        statuses.each do |old_status|
          statuses.each do |new_status|
            [member, project_admin, work_package_editor].each do |role|
              model_class.create type_variant:,
                                 role:,
                                 old_status:,
                                 new_status:
            end
          end
        end
      end
    end

    def workflows
      seed_data.lookup(seed_data_model_key).map do |workflow_data|
        type = seed_data.find_reference(workflow_data["type"])
        statuses = seed_data.find_references(workflow_data["statuses"])
        [type.default_variant, statuses]
      end
    end
  end
end

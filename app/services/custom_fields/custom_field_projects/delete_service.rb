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

module CustomFields
  module CustomFieldProjects
    class DeleteService < ::BaseServices::Delete
      def destroy(custom_field_project)
        delete_result = delete(custom_field_id: custom_field_project.custom_field_id,
                               project_id: custom_field_project.project_id)
        ActiveRecord::Type::Boolean.new.cast(delete_result)
      end

      # `custom_fields_projects` table has no `id` column, hence no primary key. #destroy method would not work
      # Note: `delete_all` goes straight to the database and does not trigger callbacks
      #
      # @return [Integer] number of rows deleted
      def delete(custom_field_id:, project_id:)
        CustomFieldsProject.transaction do
          CustomFieldsProject.where(custom_field_id:, project_id:).delete_all
        end
      end

      # Mappings have custom deletion rules that are similar to the update rules all derived from the base contract
      # Reuse the update contract to ensure that the deletion rules are consistent with the update rules
      def default_contract_class = CustomFields::CustomFieldProjects::UpdateContract
    end
  end
end

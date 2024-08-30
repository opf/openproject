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

module Settings
  module ProjectCustomFields
    module ProjectCustomFieldMapping
      class RowComponent < Projects::RowComponent
        include OpTurbo::Streamable

        def wrapper_uniq_by
          "project-#{project.id}"
        end

        def more_menu_items
          @more_menu_items ||= [more_menu_detach_project].compact
        end

        private

        def more_menu_detach_project
          project = model.first
          if User.current.admin && project.active?
            {
              scheme: :default,
              icon: nil,
              label: I18n.t("projects.settings.project_custom_fields.actions.remove_from_project"),
              href: unlink_admin_settings_project_custom_field_path(
                id: @table.params[:custom_field].id,
                project_custom_field_project_mapping: { project_id: project.id }
              ),
              data: { turbo_method: :delete }
            }
          end
        end
      end
    end
  end
end

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

module Settings
  class NewProjectSettingsForm < ApplicationForm
    settings_form do |f|
      f.check_box(
        name: :default_projects_public
      )

      f.check_box_group(
        name: :default_projects_modules,
        label: I18n.t(:setting_default_projects_modules)
      ) do |check_box_group|
        OpenProject::AccessControl.available_project_modules(sorted: true).each do |m|
          check_box_group.check_box(
            value: m.to_s,
            label: I18n.t("project_module_#{m}", default: m.to_s.humanize),
            checked: Setting.default_projects_modules.include?(m.to_s)
          )
        end
      end

      f.select_list(
        name: :new_project_user_role_id,
        label: I18n.t(:setting_new_project_user_role_id),
        caption: I18n.t(:setting_new_project_user_role_id_caption),
        input_width: :medium,
        include_blank: false
      ) do |select|
        build_new_project_user_role_options(select)
      end

      f.submit
    end

    # Adds the role options to the new_project_user_role_id select. Roles that pass the
    # `assignable_to_project_creator` filter are listed first; the currently configured role is
    # always included even when it has lost required permissions (with a label suffix), so the
    # admin can see and change the current selection.
    def build_new_project_user_role_options(select)
      assignable = ProjectRole.assignable_to_project_creator.to_a
      assignable.each { |role| add_assignable_role_option(select, role) }

      configured = ProjectRole.givable.find_by(id: Setting.new_project_user_role_id)
      add_non_qualifying_role_option(select, configured) if configured && assignable.exclude?(configured)
    end

    def add_assignable_role_option(select, role)
      select.option(
        value: role.id.to_s,
        label: role.name,
        selected: Setting.new_project_user_role_id == role.id
      )
    end

    def add_non_qualifying_role_option(select, role)
      select.option(
        value: role.id.to_s,
        label: I18n.t(:label_role_missing_permissions, role: role.name),
        selected: true
      )
    end
  end
end

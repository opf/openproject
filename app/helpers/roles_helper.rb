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

module RolesHelper
  def setable_permissions(role)
    # Use the base contract for now as we are only interested in the setable permissions
    # which do not differentiate.
    contract = Roles::BaseContract.new(role, current_user)

    contract.assignable_permissions
  end

  def grouped_setable_permissions(role)
    group_permissions_by_module(setable_permissions(role))
  end

  def group_permissions_by_module(perms)
    enabled_module_names = ::OpenProject::AccessControl.sorted_module_names(include_disabled: false)
    perms.group_by { |p| p.project_module.to_s }
         .slice(*enabled_module_names)
  end

  def permission_header_for_project_module(mod)
    if mod.blank?
      Project.model_name.human
    else
      I18n.t("permission_header_for_project_module_#{mod}",
             default: [:"project_module_#{mod}", mod.humanize])
    end
  end

  def role_names_with_permissions_preview(roles, separator: ", ")
    safe_join(
      roles.map { safe_join([h(it.name), role_permissions_preview_icon(it, ml: 1)].compact) },
      separator
    )
  end

  def role_permissions_preview_icon(role, **system_arguments)
    return unless Roles::PermissionsDialogComponent.visible_to?(User.current, role)

    anchor_id = Primer::Component.generate_id(base_name: "role-permissions-preview")
    tooltip = Primer::Alpha::Tooltip.new(
      type: :label,
      for_id: anchor_id,
      direction: :e,
      text: I18n.t("roles.permissions_dialog.preview_aria_label", role: role.name)
    )

    link = render(
      Primer::Beta::Link.new(
        id: anchor_id,
        href: role_permissions_dialog_path(role),
        muted: true,
        display: :inline_flex,
        data: { controller: "async-dialog" },
        aria: { labelledby: tooltip.id },
        test_selector: "op-roles--permissions-preview",
        **system_arguments
      )
    ) { render(Primer::Beta::Octicon.new(icon: :info, size: :xsmall)) }

    safe_join([link, render(tooltip)])
  end
end

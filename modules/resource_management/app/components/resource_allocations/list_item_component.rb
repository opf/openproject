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

module ResourceAllocations
  # A single allocation row in the work package allocations dialog: the member's
  # avatar and name (or an anonymous placeholder when the principal is not
  # visible to the current user) and the allocated hours.
  class ListItemComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include AvatarHelper

    AVATAR_SIZE = 24

    # `editable` enables the row's edit/delete menu (the caller checks the
    # permission). It stays hidden for an anonymised row regardless, since the
    # edit form would reveal the hidden user.
    def initialize(allocation:, project:, visible:, overbooked: false, editable: false)
      super

      @allocation = allocation
      @project = project
      @visible = visible
      @overbooked = overbooked
      @editable = editable
    end

    private

    attr_reader :allocation, :project

    def visible?
      @visible
    end

    def overbooked?
      @overbooked
    end

    def menu?
      @editable && visible?
    end

    def context_menu
      render(Primer::Alpha::ActionMenu.new(size: :small, anchor_align: :end)) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": t("resource_management.work_package_allocations_dialog.context_menu_label"),
                              scheme: :invisible)

        edit_item(menu)
        delete_item(menu)
      end
    end

    def edit_item(menu)
      menu.with_item(
        label: I18n.t(:button_edit),
        tag: :a,
        href: helpers.edit_project_resource_allocation_path(project, allocation),
        content_arguments: { data: { controller: "async-dialog" } }
      ) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_item(menu)
      menu.with_item(
        label: I18n.t(:button_delete),
        scheme: :danger,
        href: helpers.project_resource_allocation_path(project, allocation),
        form_arguments: {
          method: :delete,
          data: {
            turbo_confirm: t("resource_management.work_package_allocations_dialog.delete_confirmation"),
            turbo_stream: true
          }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def name
      if allocation.principal
        visible? ? allocation.principal.name : hidden_label
      else
        allocation.filter_name.presence || unassigned_label
      end
    end

    # An allocation without a user yet (filter placeholder or lost principal)
    # shows a person-add icon instead of an avatar. Sized to match the avatar so
    # the leading column keeps the same width and the row stays aligned.
    def leading_visual
      if allocation.principal
        Primer::OpenProject::AvatarWithFallback.new(size: AVATAR_SIZE, **avatar_options)
      else
        Primer::Beta::Octicon.new(icon: :"person-add", size: :medium, color: :muted, "aria-hidden": true)
      end
    end

    # Only a visible principal exposes a real avatar (and an identity-revealing
    # initials/colour seed). A hidden one falls back to a generated avatar keyed
    # to the allocation, so the user cannot be correlated.
    def avatar_options
      if visible?
        {
          src: avatar_url(allocation.principal),
          alt: allocation.principal.name,
          unique_id: allocation.principal.id
        }
      else
        {
          alt: name,
          unique_id: "resource-allocation-#{allocation.id}"
        }
      end
    end

    # Formatted per the instance's duration format setting, e.g. "2d 4h".
    def duration
      DurationConverter.output(allocation.allocated_hours)
    end

    def overbooked_icon_id
      "resource-allocation-overbooked-#{allocation.id}"
    end

    def overbooked_message
      t("resource_management.work_package_allocations_dialog.overbooked")
    end

    def hidden_label
      t("resource_management.work_package_allocations_dialog.hidden_user")
    end

    def unassigned_label
      t("resource_management.work_package_list.allocated_members.unassigned")
    end
  end
end

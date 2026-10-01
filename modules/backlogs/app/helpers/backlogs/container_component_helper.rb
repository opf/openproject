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

module Backlogs
  module ContainerComponentHelper
    def with_add_work_package_menu_group(menu, container)
      target = Backlogs::Target.for(container)
      dom_key = container == Backlogs::Target::Inbox ? :inbox : container

      with_item_group(menu) do
        next unless user_allowed?(:manage_sprint_items)

        with_add_new_work_package_item(menu, dom_key, target)
        with_add_existing_work_package_item(menu, dom_key, target)
      end
    end

    private

    def with_add_new_work_package_item(menu, dom_key, target)
      menu.with_item(
        id: dom_target(dom_key, :menu, :add_new_work_package),
        label: t(".action_menu.add_new_work_package"),
        href: new_project_work_packages_dialog_path(project, **target.to_container_params),
        content_arguments: { data: { controller: "async-dialog" } }
      ) do |item|
        item.with_leading_visual_icon(icon: :plus)
      end
    end

    def with_add_existing_work_package_item(menu, dom_key, target)
      menu.with_item(
        id: dom_target(dom_key, :menu, :add_existing_work_package),
        label: t(".action_menu.add_existing_work_package"),
        href: add_existing_dialog_project_backlogs_work_packages_path(project, target.to_list_params),
        content_arguments: { data: { controller: "async-dialog" } }
      ) do |item|
        item.with_leading_visual_icon(icon: :link)
      end
    end
  end
end

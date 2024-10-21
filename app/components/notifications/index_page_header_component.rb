# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Notifications
  class IndexPageHeaderComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(project: nil)
      super
      @project = project
    end

    def page_title
      if current_item.present?
        current_item.title
      else
        I18n.t("notifications.menu.inbox")
      end
    end

    def breadcrumb_items
      [{ href: home_path, text: helpers.organization_name },
       { href: notifications_path, text: I18n.t("js.notifications.title") },
       current_breadcrumb_element]
    end

    def current_breadcrumb_element
      if current_section && current_section.header.present?
        I18n.t("menus.breadcrumb.nested_element", section_header: current_section.header, title: page_title).html_safe
      else
        page_title
      end
    end

    def current_section
      return @current_section if defined?(@current_section)

      @current_section = Notifications::Menu
                           .new(params:, current_user: User.current)
                           .selected_menu_group
    end

    def current_item
      return @current_item if defined?(@current_item)

      @current_item = Notifications::Menu
                        .new(params:, current_user: User.current)
                        .selected_menu_item
    end
  end
end

# frozen_string_literal: true

# -- copyright
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
# ++

module Meetings
  class IndexPageHeaderComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(project: nil)
      super
      @project = project
    end

    def page_title
      I18n.t(:label_meeting_plural)
    end

    def breadcrumb_items
      [
        { href: home_path, text: helpers.organization_name },
        *([{ href: project_overview_path(@project.id), text: @project.name }] if @project.present?),
        { href: @project.present? ? project_meetings_path(@project.id) : meetings_path, text: I18n.t(:label_meeting_plural) },
        current_breadcrumb_element
      ]
    end

    def current_breadcrumb_element
      if current_section
        selected_menu = current_section.children.find(&:selected)
        if current_section.header.present?
          I18n.t("menus.breadcrumb.nested_element", section_header: current_section.header, title: selected_menu.title).html_safe
        else
          selected_menu.title
        end
      else
        page_title
      end
    end

    def current_section
      return @current_section if defined?(@current_section)

      meetings_menu = Meetings::Menu.new(params:)
      @current_section = meetings_menu.menu_items.find { |section| section.children.any?(&:selected) }
    end
  end
end

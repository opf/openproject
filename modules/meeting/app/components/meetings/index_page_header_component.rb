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
      if current_item.present?
        current_item.title
      else
        I18n.t(:label_meeting_plural)
      end
    end

    def breadcrumb_items
      [parent_element,
       { href: url_for({ controller: "meetings", action: :index, project_id: @project }),
         text: I18n.t(:label_meeting_plural) },
       current_breadcrumb_element]
    end

    def parent_element
      if @project.present?
        { href: project_overview_path(@project.id), text: @project.name }
      else
        { href: home_path, text: helpers.organization_name }
      end
    end

    def current_breadcrumb_element
      if section_present?
        I18n.t("menus.breadcrumb.nested_element", section_header: current_section.header, title: page_title).html_safe
      else
        page_title
      end
    end

    def section_present?
      current_section && current_section.header.present?
    end

    def current_section
      return @current_section if defined?(@current_section)

      @current_section = Meetings::Menu
                           .new(project: @project, params:)
                           .selected_menu_group
    end

    def current_item
      return @current_item if defined?(@current_item)

      @current_item = Meetings::Menu
                        .new(project: @project, params:)
                        .selected_menu_item
    end
  end
end

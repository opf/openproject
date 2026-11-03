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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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
        I18n.t(:label_my_meetings)
      end
    end

    def breadcrumb_items
      [
        ({ href: project_overview_path(@project.id), text: @project.name } if @project.present?),
        { href: url_for({ controller: "meetings", action: :index, project_id: @project }),
          text: I18n.t(:label_meeting_plural), skip_for_mobile: first_menu_item? },
        current_breadcrumb_element
      ].compact
    end

    def current_breadcrumb_element
      if section_present?
        helpers.nested_breadcrumb_element(current_section.header, page_title)
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
                        .new(project: @project, params: params.merge(current_href: request.path))
                        .selected_menu_item
    end

    def first_menu_item?
      current_item&.href == (@project.present? ? project_meetings_path(@project.identifier) : meetings_path)
    end
  end
end

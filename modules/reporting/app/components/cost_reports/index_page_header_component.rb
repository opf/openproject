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

module CostReports
  class IndexPageHeaderComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(query:, project: nil)
      super
      @query = query
      @project = project
      @user =  User.current
    end

    def page_title
      I18n.t(:label_meeting_plural)
    end

    def breadcrumb_items
      [parent_element,
       { href: url_for({ controller: "cost_reports", action: :index, project_id: @project }),
         text: I18n.t(:cost_reports_title) },
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
      return I18n.t(:label_new_report) unless @query.persisted?

      if current_section && current_section.header.present?
        I18n.t("menus.breadcrumb.nested_element", section_header: current_section.header, title: @query.name).html_safe
      else
        I18n.t(:label_new_report)
      end
    end

    def current_section
      return @current_section if defined?(@current_section)

      @current_section = CostReports::Menu
                           .new(project: @project, params:)
                           .selected_menu_group
    end

    def show_export_button?
      @user.allowed_in_any_work_package?(:export_work_packages, in_project: @project)
    end
  end
end

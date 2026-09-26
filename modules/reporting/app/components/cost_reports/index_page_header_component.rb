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
    include Widget::ReportingWidget::RenderWidgetInstanceMethods
    include OpTurbo::Streamable

    def initialize(query:, project: nil)
      super
      @query = query
      @project = project
      @user =  User.current
    end

    def breadcrumb_items
      [
        ({ href: project_overview_path(@project.id), text: @project.name } if @project.present?),
        { href: module_path,
          text: I18n.t(:cost_reports_title),
          skip_for_mobile: !current_section || current_section.header.blank? },
        current_breadcrumb_element
      ].compact
    end

    def current_breadcrumb_element
      return I18n.t(:label_new_report) unless @query.persisted?

      if current_section && current_section.header.present?
        helpers.nested_breadcrumb_element(current_section.header, @query.name)
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

    def export_path(format)
      report_location = @query.persisted? ? { action: :show, id: @query.id } : { action: :index }

      url_for({ controller: "cost_reports", **report_location, format:, project_id: @project, **@query.to_query_params })
    end

    def module_path
      @project.present? ? cost_reports_path(@project) : global_cost_reports_path
    end
  end
end

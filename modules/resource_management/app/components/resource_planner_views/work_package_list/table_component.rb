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

module ResourcePlannerViews::WorkPackageList
  class TableComponent < ::OpPrimer::BorderBoxTableComponent
    columns :subject, :priority, :dates, :allocation, :allocated_members

    mobile_columns :subject, :priority

    attr_reader :view, :project, :resource_planner

    def initialize(view:, project:, resource_planner:, **)
      super(**)

      @view = view
      @project = project
      @resource_planner = resource_planner
    end

    def manual? = view.manually_picked?

    main_column :subject

    def sortable? = false

    def paginated? = false

    def has_actions? = true

    def mobile_title
      I18n.t("resource_management.work_package_list.mobile_title")
    end

    def headers
      @headers ||= [
        [:subject, { caption: WorkPackage.human_attribute_name(:subject) }],
        [:priority, { caption: WorkPackage.human_attribute_name(:priority) }],
        [:dates, { caption: I18n.t("resource_management.work_package_list.columns.dates") }],
        [:allocation, { caption: I18n.t("resource_management.work_package_list.columns.allocation") }],
        [:allocated_members, { caption: I18n.t("resource_management.work_package_list.columns.allocated_members") }]
      ]
    end

    def columns
      @columns ||= headers.map(&:first)
    end

    def blank_title
      I18n.t("resource_management.work_package_list.blank.title")
    end

    def blank_description
      I18n.t("resource_management.work_package_list.blank.description")
    end
  end
end

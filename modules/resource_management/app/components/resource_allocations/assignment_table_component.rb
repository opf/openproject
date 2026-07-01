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
  # The Staffing list: every generic allocation in the project still awaiting a
  # user, sorted by start date. A row opens the assignment dialog.
  class AssignmentTableComponent < ::OpPrimer::BorderBoxTableComponent
    columns :resource, :work_package, :dates, :requested_time

    mobile_columns :resource, :dates

    main_column :resource, :work_package

    attr_reader :project, :visible_work_package_ids

    def initialize(project:, visible_work_package_ids: Set.new, **)
      super(**)

      @project = project
      @visible_work_package_ids = visible_work_package_ids
    end

    # The base derives the row class from the namespace; ours lives at the
    # resource_allocations root next to the other allocation components.
    def self.row_class
      ResourceAllocations::AssignmentRowComponent
    end

    def sortable? = false

    def paginated? = false

    def has_actions? = true

    def mobile_title
      I18n.t("resource_management.staffing.title")
    end

    def headers
      @headers ||= [
        [:resource, { caption: I18n.t("resource_management.staffing.columns.resource") }],
        [:work_package, { caption: I18n.t("resource_management.staffing.columns.work_package") }],
        [:dates, { caption: I18n.t("resource_management.staffing.columns.dates") }],
        [:requested_time, { caption: I18n.t("resource_management.staffing.columns.requested_time") }]
      ]
    end

    def columns
      @columns ||= headers.map(&:first)
    end

    def blank_title
      I18n.t("resource_management.staffing.blank.title")
    end

    def blank_description
      I18n.t("resource_management.staffing.blank.description")
    end
  end
end

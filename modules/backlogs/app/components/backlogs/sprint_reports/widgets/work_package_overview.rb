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
# ++

module Backlogs
  module SprintReports
    module Widgets
      class WorkPackageOverview < Grids::WidgetComponent
        param :sprint
        param :project

        def title
          t("backlogs.show_work_package_overview")
        end

        def resolved_percentage
          return 0 if total_work_packages_count.zero?

          (resolved_work_packages_count.to_f / total_work_packages_count * 100).round
        end

        private

        def resolved_summary_text
          t(
            "backlogs.sprint_reports.widgets.work_package_overview.resolved_summary",
            percentage: resolved_percentage,
            resolved: resolved_work_packages_count,
            total: total_work_packages_count
          )
        end

        def work_packages
          @work_packages ||= WorkPackage.where(sprint:, project:)
        end

        def resolved_work_packages_count
          @resolved_work_packages_count ||= work_packages.where(status_id: project.done_status_ids).count
        end

        def total_work_packages_count
          @total_work_packages_count ||= work_packages.count
        end
      end
    end
  end
end

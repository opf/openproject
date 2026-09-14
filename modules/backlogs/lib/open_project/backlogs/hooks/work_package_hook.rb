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

module OpenProject::Backlogs
  module Hooks
    class WorkPackageHook < ::OpenProject::Hook::ViewListener
      # Adds the Sprint and Backlog bucket fields to the work package bulk-edit form.
      #
      # Only shown when all selected work packages share a single project (context[:project]
      # is only set in that case, see WorkPackages::BulkController#find_work_packages), that
      # project has backlogs enabled, and the current user is allowed to manage sprint items.
      def view_work_packages_bulk_edit_details_bottom(context = {})
        project = context[:project]
        return "" unless project&.backlogs_enabled? &&
                          User.current.allowed_in_project?(:manage_sprint_items, project)

        context[:hook_caller].render(
          partial: "work_packages/bulk/sprint_and_backlog_bucket_fields",
          locals: {
            assignable_sprints: Sprint.assignable(project:, user: User.current).order_by_date,
            backlog_buckets: BacklogBucket.visible(User.current).for_project(project)
          }
        )
      end
    end
  end
end

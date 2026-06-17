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

module Backlogs::Concerns
  module ContainerLoading
    extend ActiveSupport::Concern

    def load_container_data
      load_sprint_data
      load_backlog_data
    end

    def load_sprint_data
      @sprints = Sprint.for_project(@project)
                       .not_completed
                       .order_by_date
                       .includes(:project, :task_boards, :goals)
      @active_sprint_ids = @sprints.select(&:active?).map(&:id)

      @work_packages_by_sprint_id = WorkPackage
                                      .where(sprint: @sprints, project: @project)
                                      .includes(:type, :status, :assigned_to, :priority, :parent)
                                      .order_by_position
                                      .group_by(&:sprint_id)
    end

    def load_backlog_data
      @backlog_buckets = BacklogBucket.for_project(@project)

      # Includes the work packages of both the buckets and the inbox.
      # This has the drawback of loading more work packages than are displayed in the inbox as pagination
      # will only show the top 50 and lowest 10 work packages.
      # But doing only a single query (+ includes) to the database has its benefits, and currently this seems quicker.
      @work_packages_by_backlog_id = WorkPackage
                                       .in_backlog_for(project: @project)
                                       .includes(:type, :status, :assigned_to, :priority, :parent)
                                       .group_by(&:backlog_bucket_id)
    end
  end
end

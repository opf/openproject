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

module Backlogs
  module CommonHelper
    include PermittedParamsHelper

    def user_allowed?(permission, project: nil)
      current_user.allowed_in_project?(permission, project || self.project)
    end

    def backlog_bucket_creation_allowed?
      user_allowed?(:create_sprints)
    end

    def sprint_creation_allowed?
      user_allowed?(:create_sprints) &&
        !project.receive_shared_sprints?
    end

    def sprint_management_allowed?
      user_allowed?(:share_sprint)
    end

    def backlog_filters
      RequestStore.fetch(:backlog_filters) do
        Backlogs::BacklogFilters.from_params(permitted_params.backlog_filters)
      end
    end

    def backlog_filter_params
      backlog_filters.to_h
    end

    def all_sprints_for(project)
      Sprint.for_project(project).not_completed.order_by_date.includes(:project, :task_boards, :goals)
    end

    def all_buckets_for(project)
      BacklogBucket.for_project(project)
    end

    def filtered_sprints_for(project)
      relation = all_sprints_for(project)
      backlog_filters.sprint_ids.present? ? relation.where(id: backlog_filters.sprint_ids) : relation
    end

    def filtered_buckets_for(project)
      return all_buckets_for(project) if backlog_filters.bucket_ids.nil?

      bucket_ids = backlog_filters.bucket_ids.reject { |id| id == "inbox" }
      all_buckets_for(project).where(id: bucket_ids)
    end
  end
end

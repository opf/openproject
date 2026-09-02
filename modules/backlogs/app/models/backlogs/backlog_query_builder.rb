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
  # Builds a transient, project-scoped work-package Query for the Backlogs show page.
  class BacklogQueryBuilder
    def initialize(project:, user:, params:)
      @project = project
      @user = user
      @params = params
    end

    def build(extra_filters: [])
      query = Query.new(project: @project, user: @user, include_subprojects: false)

      generic_filters.each { |filter| query.add_filter(filter[:attribute], filter[:operator], filter[:values]) }

      # Limit the scope of the query to the current project.
      query.add_filter("project_id", "=", [@project.id.to_s])

      extra_filters.each { |field, operator, values| query.add_filter(field, operator, values) }

      query.sort_criteria = [%w[position asc], %w[id asc]]

      query.valid_subset!
      query
    end

    def build_sprint_work_packages(sprint_ids:)
      build(extra_filters: [[:sprint_id, "=", sprint_ids]])
       .results
       .work_packages
    end

    # Since the Query class does not support "OR" conditions, separate queries are generated for the
    # inbox and the bucket ids. The resulting arel queries are joined with an `.or` query.
    def build_backlog_work_packages(bucket_ids:, show_inbox:)
      backlog_conditions(bucket_ids:, show_inbox:)
        .map { |extra_filters| build(extra_filters:).results.work_packages }
        .reduce { |relation, other| relation.or(other) }
        .merge(WorkPackage.in_backlog_for(project: @project))
    end

    private

    def generic_filters
      return [] if @params[:filters].blank?

      Queries::ParamsParser.parse(@params).fetch(:filters, [])
    rescue JSON::ParserError
      []
    end

    def backlog_conditions(bucket_ids:, show_inbox:)
      # No bucket_ids param at all means no explicit bucket selection was made. in_backlog_for
      # (merged in by the caller) already scopes to buckets + inbox, so no extra restriction is needed.
      return [[]] if bucket_ids.nil?

      conditions = []
      conditions << [[:backlog_bucket_id, "=", bucket_ids.map(&:to_s)]] if bucket_ids.present?
      conditions << [[:backlog_inbox, "=", [OpenProject::Database::DB_VALUE_TRUE]]] if show_inbox
      conditions
    end
  end
end

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

module Members::CurrentRateColumn
  extend ActiveSupport::Concern

  prepended do
    add_column :current_rate
    options :current_user
  end

  def sort_collection(query, sort_clause, sort_columns)
    q = super(query, sort_clause.gsub("current_rate", "COALESCE(rate, 0.0)"), sort_columns)

    if sort_columns.include? :current_rate
      join_rate q
    else
      q
    end
  end

  ##
  # Joins user's rates so the results can be sorted by them.
  # Each member is paired by one rate row of either (if present, in this order):
  #
  #   1) a user's rate in the given project
  #   2) a user's rate in one of the given project's parents
  #   3) a user's default rate
  #
  # This mirrors the behaviour as implemented in `HourlyRate#at_date_for_user_in_project`.
  def join_rate(query)
    query.joins(
      ActiveRecord::Base.sanitize_sql_array(
        [RATE_JOIN_SQL, { project_id: project.id, parent_project_ids:, today: Time.zone.today }]
      )
    )
  end

  RATE_JOIN_SQL = <<~SQL.squish
    LEFT JOIN rates ON rates.id = (
      SELECT rate_union.id
      FROM (
        /* rates in the project */
        SELECT * FROM rates
        WHERE project_id = :project_id AND valid_from <= :today
        UNION
        /* rates in the ancestors of the project */
        SELECT * FROM (
          SELECT rates.* FROM rates
          WHERE project_id IN (:parent_project_ids) AND valid_from <= :today
        ) AS parent_project_rates
        UNION
        /* default rates of the users */
        SELECT * FROM rates
        WHERE type = 'DefaultHourlyRate' AND valid_from <= :today
      ) AS rate_union
      LEFT JOIN projects ON rate_union.project_id = projects.id
      WHERE rate_union.user_id = members.user_id AND rate_union.rate IS NOT NULL
      GROUP BY project_id, valid_from, projects.lft, rate_union.id
      ORDER BY
        CASE
          WHEN project_id = :project_id THEN 0
          WHEN project_id IS NOT NULL THEN 1
          ELSE 2
        END ASC, projects.lft DESC, valid_from DESC
      LIMIT 1
    )
  SQL

  def parent_project_ids
    project.ancestors.pluck(:id).presence || [0]
  end

  def project
    options[:project]
  end

  def columns
    if costs_enabled?
      super
    else
      super - [:current_rate]
    end
  end

  def costs_enabled?
    if @costs_enabled.nil?
      @costs_enabled = project.present? && project.module_enabled?(:costs)
    end

    @costs_enabled
  end
end

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

module Queries::Projects::Filters::FilterOnProjectPhase
  extend ActiveSupport::Concern
  include Queries::Operators::DateRangeClauses

  def type
    :date
  end

  def available_operators
    [
      ::Queries::Operators::Today,
      ::Queries::Operators::ThisWeek,
      ::Queries::Operators::OnDate,
      ::Queries::Operators::BetweenDate,
      ::Queries::Operators::None
    ]
  end

  def available?
    User.current.allowed_in_any_project?(:view_project_phases)
  end

  def where
    scope = case operator.to_sym
            when Queries::Operators::OnDate.to_sym
              on_date
            when Queries::Operators::Today.to_sym
              on_today
            when Queries::Operators::BetweenDate.to_sym
              between_date
            when Queries::Operators::ThisWeek.to_sym
              this_week
            when Queries::Operators::None.to_sym
              none
            else
              raise "Unknown operator #{operator}"
            end

    scope
      .arel
      .exists
  end

  private

  def on_date
    raise SubclassResponsibilityError
  end

  def on_today
    raise SubclassResponsibilityError
  end

  def between_date
    raise SubclassResponsibilityError
  end

  def this_week
    raise SubclassResponsibilityError
  end

  def none
    raise SubclassResponsibilityError
  end

  def project_phase_scope_limit(scope)
    scope
  end

  def phase_where_on(start_date, finish_date = start_date)
    project_phase_scope
      .where(date_range_clause(Project::Phase.table_name, "start_date", nil, start_date))
      .where(date_range_clause(Project::Phase.table_name, "finish_date", finish_date, nil))
  end

  def phase_where_between(start_date, finish_date)
    project_phase_scope
      .where(date_range_clause(Project::Phase.table_name, "start_date", start_date, nil))
      .where(date_range_clause(Project::Phase.table_name, "finish_date", nil, finish_date))
  end

  def phase_overlaps_this_week
    project_phase_scope
      .where.not(start_date: nil)
      .where.not(finish_date: nil)
      .where(
        <<~SQL.squish, beginning_of_week, end_of_week
          daterange(#{Project::Phase.table_name}.start_date,
                    #{Project::Phase.table_name}.finish_date,
                    '[]')
          &&
          daterange(?, ?, '[]')
        SQL
      )
  end

  def phase_none
    project_phase_scope
      .where(start_date: nil)
      .where(finish_date: nil)
  end

  def parsed_start
    values.first.present? ? Date.parse(values.first) : nil
  end

  def parsed_end
    values.last.present? ? Date.parse(values.last) : nil
  end

  def today
    Time.zone.today
  end

  def beginning_of_week
    OpenProject::Internationalization::Date.time_at_beginning_of_week
  end

  def end_of_week
    (beginning_of_week + 6.days).end_of_day
  end

  def project_phase_scope
    project_phase_scope = Project::Phase
      .where("#{Project::Phase.table_name}.project_id = #{Project.table_name}.id")
      .where(project_id: Project.allowed_to(User.current, :view_project_phases))
      .active

    project_phase_scope_limit(project_phase_scope)
  end

  delegate :connection, to: :"ActiveRecord::Base"
end

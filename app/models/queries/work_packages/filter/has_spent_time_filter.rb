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

class Queries::WorkPackages::Filter::HasSpentTimeFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::Operators::DateRangeClauses

  def type
    :date
  end

  def self.key
    :has_spent_time
  end

  def available_operators
    [Queries::Operators::BetweenDate]
  end

  def type_strategy
    @type_strategy ||= Queries::Filters::Strategies::DateInterval.new(self)
  end

  def where
    return nil if values.blank?

    from_date = Date.parse(values[0]) if values[0].present?
    to_date   = Date.parse(values[1]) if values[1].present?
    return nil if from_date.nil? && to_date.nil?

    allowed_project_ids = Project.allowed_to(User.current, :view_time_entries).select(:id).to_sql

    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM time_entries
        WHERE time_entries.entity_type = 'WorkPackage'
          AND time_entries.entity_id = work_packages.id
          AND #{date_range_clause('time_entries', 'spent_on', from_date, to_date)}
          AND time_entries.hours > 0
          AND time_entries.ongoing = false
          AND time_entries.project_id IN (#{allowed_project_ids})
      )
    SQL
  rescue Date::Error
    nil
  end

  def allowed_values
    []
  end

  delegate :connection, to: :"ActiveRecord::Base"
end

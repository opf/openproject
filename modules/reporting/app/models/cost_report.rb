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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# A saved cost report: the presentation of a CostReportQuery.
#
# The query owns which dimensions are aggregated; this view owns how they are
# laid out - which dimensions go on rows, which on columns - plus the selected
# unit tab.
class CostReport < PersistedView
  PIVOT_AXES = %i[pivot_rows pivot_columns].freeze

  # The permissions the CostReportsController registers its view actions for.
  VIEW_PERMISSIONS = %i[
    view_time_entries
    view_own_time_entries
    view_cost_entries
    view_own_cost_entries
  ].freeze

  store_attribute :options, :pivot_rows, :json, default: []
  store_attribute :options, :pivot_columns, :json, default: []
  store_attribute :options, :unit_id, :integer

  validates :query, presence: true
  validate :pivot_axes_match_query_group_bys

  before_validation :set_category

  def build_default_query
    CostReportQuery.new(project:, principal:)
  end

  # The axes are the user facing configuration; the query's group_bys are
  # derived from them so the two can never drift apart.
  def apply_pivot_configuration(rows:, columns:)
    self.pivot_rows = Array(rows).map(&:to_s)
    self.pivot_columns = Array(columns).map(&:to_s)

    query.group_bys = (pivot_columns + pivot_rows).map { |name| query.group_by_for(name) }
  end

  # Mirrors the CostReportsController: any of the four permissions that grant
  # access to the report pages is enough to read a report, and a report is
  # readable if it is public or the user's own. Note that there is deliberately
  # no exception for admins - they cannot read somebody else's private report
  # either.
  def visible?(user)
    return false unless public? || principal == user

    if project
      VIEW_PERMISSIONS.any? { |permission| user.allowed_in_project?(permission, project) }
    else
      VIEW_PERMISSIONS.any? { |permission| user.allowed_in_any_project?(permission) }
    end
  end

  private

  def set_category
    self.category ||= :cost_report
  end

  def pivot_axes_match_query_group_bys
    return if query.nil?

    return if (pivot_columns + pivot_rows).sort == query.group_bys.map { |group_by| group_by.name.to_s }.sort

    errors.add(:base, :pivot_axes_do_not_match_group_bys)
  end
end

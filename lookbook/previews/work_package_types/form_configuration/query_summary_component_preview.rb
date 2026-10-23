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

class WorkPackageTypes::FormConfiguration::QuerySummaryComponentPreview < ViewComponent::Preview
  def simple
    render_summary { it.column_names = %i[id subject type project status priority assigned_to] }
  end

  def detailed
    render_summary do |query|
      query.column_names = %i[id subject type project status priority assigned_to start_date due_date]
      query.add_filter("subject", "~", ["release"])
      query.sort_criteria = [%w[priority desc], %w[subject asc]]
      query.timestamps = ["oneWeekAgo@09:00+01:00", "PT0S"]
    end
  end

  def unavailable
    render_summary do |query|
      query.column_names = %i[id subject removed_column]
      query.add_filter("cf_999999", "=", ["1"])
    end
  end

  private

  def render_summary
    query = Query.new(name: "Preview")
    query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
    yield query

    render(WorkPackageTypes::FormConfiguration::QuerySummaryComponent.new(
             rows: WorkPackageTypes::FormConfiguration::QuerySummary.new(query).rows
           ))
  end
end

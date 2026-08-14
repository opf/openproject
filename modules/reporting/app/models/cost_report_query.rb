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

# The persisted definition of a cost report: which entries it covers (filters)
# and which dimensions it aggregates over (group_bys).
#
# Only the definition lives here. Computing the pivot is still the reporting
# engine's job - see CostQuery and Report::Chainable - because the underlying
# relation is a UNION of time_entries and cost_entries rather than a scope over
# a single model, and row level permissions are enforced inside that SQL by
# CostQuery::Filter::PermissionFilter.
#
# Which axis a group by is rendered on is view state and lives on CostReport.
class CostReportQuery < PersistedQuery
  scope :visible, ->(user = User.current) { where(principal: user) }

  def self.model
    Entry::Delegator
  end

  # The reporting engine builds its own SQL from the chain, so there is no
  # ActiveRecord scope to fall back to here.
  def default_scope
    raise NotImplementedError, "Cost reports are computed by the reporting engine" # rubocop:disable OpenProject/NoNotImplementedError
  end

  def results
    engine_query.result
  end

  # Replays this definition into a reporting engine chain.
  def engine_query
    CostQuery.new(project:).tap do |query|
      filters.each do |filter|
        query.filter(filter.name, operator: filter.operator, values: filter.values)
      end

      group_bys.each do |group_by|
        query.group_by(group_by.name)
      end
    end
  end

  register_query do
    filter Queries::CostReports::Filters::ActivityIdFilter
    filter Queries::CostReports::Filters::AssignedToIdFilter
    filter Queries::CostReports::Filters::AuthorIdFilter
    filter Queries::CostReports::Filters::BudgetIdFilter
    filter Queries::CostReports::Filters::CategoryIdFilter
    filter Queries::CostReports::Filters::CostTypeIdFilter
    filter Queries::CostReports::Filters::CreatedOnFilter
    filter Queries::CostReports::Filters::CustomFieldFilter
    filter Queries::CostReports::Filters::DueDateFilter
    filter Queries::CostReports::Filters::LoggedByIdFilter
    filter Queries::CostReports::Filters::OverriddenCostsFilter
    filter Queries::CostReports::Filters::PriorityIdFilter
    filter Queries::CostReports::Filters::ProjectIdFilter
    filter Queries::CostReports::Filters::ResponsibleIdFilter
    filter Queries::CostReports::Filters::SpentOnFilter
    filter Queries::CostReports::Filters::StartDateFilter
    filter Queries::CostReports::Filters::StatusIdFilter
    filter Queries::CostReports::Filters::SubjectFilter
    filter Queries::CostReports::Filters::TmonthFilter
    filter Queries::CostReports::Filters::TweekFilter
    filter Queries::CostReports::Filters::TyearFilter
    filter Queries::CostReports::Filters::TypeIdFilter
    filter Queries::CostReports::Filters::UpdatedOnFilter
    filter Queries::CostReports::Filters::UserIdFilter
    filter Queries::CostReports::Filters::VersionIdFilter
    filter Queries::CostReports::Filters::WorkPackageIdFilter

    group_by Queries::CostReports::GroupBys::ActivityId
    group_by Queries::CostReports::GroupBys::AssignedToId
    group_by Queries::CostReports::GroupBys::AuthorId
    group_by Queries::CostReports::GroupBys::BudgetId
    group_by Queries::CostReports::GroupBys::CategoryId
    group_by Queries::CostReports::GroupBys::CostTypeId
    group_by Queries::CostReports::GroupBys::CustomField
    group_by Queries::CostReports::GroupBys::LoggedById
    group_by Queries::CostReports::GroupBys::PriorityId
    group_by Queries::CostReports::GroupBys::ProjectId
    group_by Queries::CostReports::GroupBys::SpentOn
    group_by Queries::CostReports::GroupBys::StatusId
    group_by Queries::CostReports::GroupBys::Tmonth
    group_by Queries::CostReports::GroupBys::Tyear
    group_by Queries::CostReports::GroupBys::TypeId
    group_by Queries::CostReports::GroupBys::UserId
    group_by Queries::CostReports::GroupBys::VersionId
    group_by Queries::CostReports::GroupBys::Week
    group_by Queries::CostReports::GroupBys::WorkPackageId
  end
end

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

module Queries::Operators
  OPERATORS = [
    Queries::Operators::Ago,
    Queries::Operators::All,
    Queries::Operators::BetweenDate,
    Queries::Operators::Blocked,
    Queries::Operators::Blocks,
    Queries::Operators::Child,
    Queries::Operators::Children,
    Queries::Operators::ClosedWorkPackages,
    Queries::Operators::Contains,
    Queries::Operators::DaysAgo,
    Queries::Operators::Duplicated,
    Queries::Operators::Duplicates,
    Queries::Operators::Equals,
    Queries::Operators::Everywhere,
    Queries::Operators::Follows,
    Queries::Operators::GreaterOrEqual,
    Queries::Operators::GreaterOrEqualDate,
    Queries::Operators::GreaterThan,
    Queries::Operators::In,
    Queries::Operators::Includes,
    Queries::Operators::InLessThan,
    Queries::Operators::InMoreThan,
    Queries::Operators::LessOrEqual,
    Queries::Operators::LessOrEqualDate,
    Queries::Operators::LessThan,
    Queries::Operators::LessThanAgo,
    Queries::Operators::MoreThanAgo,
    Queries::Operators::None,
    Queries::Operators::NotContains,
    Queries::Operators::NotEquals,
    Queries::Operators::NotProjectWithSubprojects,
    Queries::Operators::NotWorkPackageWithDescendants,
    Queries::Operators::OnDate,
    Queries::Operators::OpenWorkPackages,
    Queries::Operators::Parent,
    Queries::Operators::PartOf,
    Queries::Operators::Past,
    Queries::Operators::Precedes,
    Queries::Operators::ProjectWithSubprojects,
    Queries::Operators::Relates,
    Queries::Operators::Required,
    Queries::Operators::Requires,
    Queries::Operators::Set,
    Queries::Operators::StartsWith,
    Queries::Operators::ThisWeek,
    Queries::Operators::Today,
    Queries::Operators::Unset,
    Queries::Operators::Upcoming,
    Queries::Operators::WorkPackageWithDescendants
  ].index_by { |o| o.symbol.to_s }.freeze
end

#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Queries::Operators
  operators = [
    Queries::Operators::GreaterOrEqual,
    Queries::Operators::LessOrEqual,
    Queries::Operators::Equals,
    Queries::Operators::NotEquals,
    Queries::Operators::None,
    Queries::Operators::All,
    Queries::Operators::Contains,
    Queries::Operators::NotContains,
    Queries::Operators::InLessThan,
    Queries::Operators::InMoreThan,
    Queries::Operators::In,
    Queries::Operators::Today,
    Queries::Operators::ThisWeek,
    Queries::Operators::LessThanAgo,
    Queries::Operators::MoreThanAgo,
    Queries::Operators::Ago,
    Queries::Operators::OnDate,
    Queries::Operators::BetweenDate,
    Queries::Operators::Everywhere,
    Queries::Operators::Relates,
    Queries::Operators::Duplicates,
    Queries::Operators::Duplicated,
    Queries::Operators::Blocks,
    Queries::Operators::Blocked,
    Queries::Operators::Follows,
    Queries::Operators::Precedes,
    Queries::Operators::Includes,
    Queries::Operators::PartOf,
    Queries::Operators::Requires,
    Queries::Operators::Required,
    Queries::Operators::Parent,
    Queries::Operators::Children
  ]

  OPERATORS = Hash[*(operators.map { |o| [o.symbol.to_s, o] }).flatten].freeze
end

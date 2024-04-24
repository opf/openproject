#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Queries::Days::DayQuery
  include Queries::BaseQuery
  include Queries::UnpersistedQuery

  def self.model
    Day
  end

  def default_scope
    Day.default_scope
  end

  ##
  # The dates interval filter needs to adjust the `from` clause of the query.
  # If there are multiple filters with custom from clause (currently not possible),
  # the first one is applied and the rest is ignored.
  def apply_filters(scope)
    scope = super(scope)
    from_clause_filter = filters.find(&:from)
    scope = scope.from(from_clause_filter.from) if from_clause_filter
    scope
  end

  def results
    super.reorder(date: :asc)
  end
end

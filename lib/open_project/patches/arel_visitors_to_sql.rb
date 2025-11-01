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

# Necessary extension of Arel::Visitors::ToSql to support the CTE provider/collector
# pattern for moving CTEs from somewhere within the subquery to the topmost
# statement for increased performance.
module OpenProject::Patches::ArelVisitorsToSql
  def visit_OpenProject_ActiveRecordExtensions_ProviderStatement(node, collector) # rubocop:disable Naming/MethodName
    # Since there might not always be a provider to collect the CTE from within
    # the arel ast, fall back to inlining the registered sql.
    collector << if node.provided_cte_collected?
                   "SELECT * from #{nod.provided_cte}"
                 else
                   OpenProject::ActiveRecordExtensions::Cte::Aggregation.registered[node.provided_cte]
                 end

    collector
  end
end

Arel::Visitors::ToSql.prepend(OpenProject::Patches::ArelVisitorsToSql)

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

class CostQuery::GroupBy::VersionId < Report::GroupBy::Base
  # Keep the derived "version_id" field bare so it renders through the existing
  # :version_id branch; the table name qualifies it for the SELECT and GROUP BY.
  table_name "work_package_versions"
  applies_for :label_work_package_attributes

  # Resolved per report-build rather than via the join_table DSL (which freezes
  # the join at class load) so the multiple-versions feature flag can switch
  # between all target versions and the primary one. Must return the same string
  # as the filter so the engine collapses them into a single join.
  def self.table_joins
    [[CostQuery::WorkPackageTargetVersionJoin.sql]]
  end

  def self.label
    WorkPackage.human_attribute_name(Setting::WorkPackageMultipleVersions.active? ? :target_versions : :version)
  end
end

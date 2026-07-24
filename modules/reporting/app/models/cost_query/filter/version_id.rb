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

class CostQuery::Filter::VersionId < Report::Filter::Base
  use :null_operators
  db_field "work_package_versions.version_id"
  applies_for :label_work_package_attributes

  # Resolved per report-build rather than via the join_table DSL (which freezes
  # the join at class load) so the multiple-versions feature flag can switch
  # between all target versions and the primary one.
  def self.table_joins
    [[CostQuery::WorkPackageTargetVersionJoin.sql]]
  end

  def self.label
    WorkPackage.human_attribute_name(Setting::WorkPackageMultipleVersions.active? ? :target_versions : :version)
  end

  def self.available_values(*)
    versions = Version.where(project_id: Project.visible.map(&:id))
    versions.map { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort_by { |a| a.first.to_s + a.second.to_s }
  end
end

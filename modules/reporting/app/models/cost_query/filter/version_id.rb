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
  # Filters on the target-version join rows instead of the deprecated
  # work_packages.version_id column. The field is table-qualified because that
  # column still exists alongside until it is dropped.
  join_table WorkPackage => [Entry, :entity]
  join_table "LEFT OUTER JOIN work_package_versions " \
             "ON work_package_versions.work_package_id = work_packages.id " \
             "AND work_package_versions.kind = 'target'"
  db_field "work_package_versions.version_id"
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:version)
  end

  def self.available_values(*)
    versions = Version.where(project_id: Project.visible.map(&:id))
    versions.map { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort_by { |a| a.first.to_s + a.second.to_s }
  end
end

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

module CostQuery::WorkPackageTargetVersionJoin
  # Reaches a work package's target versions from the reporting entries. The
  # join is one-to-many, so a work package with several target versions is
  # reported under each of them. The filter and group-by must share the exact
  # same statement so the engine collapses it to a single join when both apply.
  #
  # entries.entity_id is polymorphic (a time entry can point at a Meeting whose
  # id collides with a work package's), so the entity_type guard lives in the ON
  # clause: it keeps LEFT semantics for the group-by (non-work-package entries
  # stay, grouped under "no version") instead of dropping them via WHERE.
  JOIN = <<~SQL.squish
    LEFT OUTER JOIN work_package_versions
      ON work_package_versions.work_package_id = entries.entity_id
     AND entries.entity_type = 'WorkPackage'
     AND work_package_versions.kind = 'target'
  SQL
end

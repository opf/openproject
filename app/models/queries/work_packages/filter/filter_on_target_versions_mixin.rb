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

module Queries::WorkPackages::Filter::FilterOnTargetVersionsMixin
  STATUS_BY_OPERATOR = { "o" => "open", "c" => "closed", "l" => "locked" }.freeze

  private

  def target_versions_where
    case operator
    when "!" # is not
      "NOT (#{target_version_matching_values})"
    when "!*" # empty
      "NOT (#{any_target_version_associated})"
    when "*" # not empty
      any_target_version_associated
    when "o", "c", "l" # version status
      target_version_with_status(STATUS_BY_OPERATOR[operator])
    else # "=" is (or)
      target_version_matching_values
    end
  end

  def any_target_version_associated
    "EXISTS (#{target_associations.select(1).to_sql})"
  end

  def target_version_matching_values
    "EXISTS (#{target_associations.where(version_id: values).select(1).to_sql})"
  end

  def target_version_with_status(status)
    sub = target_associations
            .joins(:version)
            .where(Version.table_name => { status: })
            .select(1)
    "EXISTS (#{sub.to_sql})"
  end

  def target_associations
    WorkPackageVersion
      .where(kind: "target")
      .where("#{WorkPackageVersion.table_name}.work_package_id = #{WorkPackage.table_name}.id")
  end
end

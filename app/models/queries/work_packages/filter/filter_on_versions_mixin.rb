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

module Queries::WorkPackages::Filter::FilterOnVersionsMixin
  STATUS_BY_OPERATOR = { "o" => "open", "c" => "closed", "l" => "locked" }.freeze

  def allowed_values
    # as we no longer display the allowed values, the first value is irrelevant
    @allowed_values ||= versions.pluck(:id).map { |id| [id.to_s, id.to_s] }
  end

  def available_operators
    [
      Queries::Operators::EqualsOr,
      Queries::Operators::NotEquals,
      Queries::Operators::All,
      Queries::Operators::None,
      Queries::Operators::Versions::OpenStatus,
      Queries::Operators::Versions::LockedStatus,
      Queries::Operators::Versions::ClosedStatus
    ]
  end

  def type
    :list_optional
  end

  def ar_object_filter?
    true
  end

  def where
    versions_where
  end

  def value_objects
    available_versions = versions.index_by(&:id)

    values
      .filter_map { |version_id| available_versions[version_id.to_i] }
  end

  def operator_strategy
    case operator
    when "o"
      Queries::Operators::Versions::OpenStatus
    when "c"
      Queries::Operators::Versions::ClosedStatus
    when "l"
      Queries::Operators::Versions::LockedStatus
    else
      super
    end
  end

  private

  def versions
    if project
      project.shared_versions
    else
      Version.visible
    end
  end

  def versions_where
    case operator
    when "!" # is not
      "NOT (#{version_matching_values})"
    when "!*" # empty
      "NOT (#{any_version_associated})"
    when "*" # not empty
      any_version_associated
    when "o", "c", "l" # version status
      version_with_status(STATUS_BY_OPERATOR[operator])
    else # "=" is (or)
      version_matching_values
    end
  end

  def any_version_associated
    "EXISTS (#{version_associations.select(1).to_sql})"
  end

  def version_matching_values
    "EXISTS (#{version_associations.where(version_id: values).select(1).to_sql})"
  end

  def version_with_status(status)
    sub = version_associations
            .joins(:version)
            .where(Version.table_name => { status: })
            .select(1)
    "EXISTS (#{sub.to_sql})"
  end

  def version_associations
    WorkPackageVersion
      .where(kind: version_kind)
      .where("#{WorkPackageVersion.table_name}.work_package_id = #{WorkPackage.table_name}.id")
  end
end

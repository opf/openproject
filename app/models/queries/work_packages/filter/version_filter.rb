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

class Queries::WorkPackages::Filter::VersionFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include ::Queries::WorkPackages::Filter::FilterOnTargetVersionsMixin

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

  def human_name
    WorkPackage.human_attribute_name("version")
  end

  # Filter on `target_versions` as it is replacing
  # the legacy `work_package.version_id` column
  def where
    target_versions_where
  end

  def joins
    return if filter_on_target_versions?

    case operator
    when "o", "c", "l"
      :version
    end
  end

  def self.key
    :version_id
  end

  def ar_object_filter?
    true
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

  def filter_on_target_versions?
    Setting::WorkPackageMultipleVersions.active?
  end

  def versions
    if project
      project.shared_versions
    else
      Version.visible
    end
  end
end

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

# Query rows store the canonical version name regardless of the
# work_package_multiple_versions setting; readers translate it to whichever
# name the setting currently offers.
module Queries::WorkPackages::VersionNames
  SELECTS = %w[version target_versions].freeze
  FILTERS = %w[version_id target_version_id].freeze

  def self.canonical_select(name)
    translate(name, SELECTS, "target_versions")
  end

  def self.active_select(name)
    translate(name, SELECTS, Setting::WorkPackageMultipleVersions.active? ? "target_versions" : "version")
  end

  def self.canonical_filter(key)
    translate(key, FILTERS, "target_version_id")
  end

  def self.active_filter(key)
    translate(key, FILTERS, Setting::WorkPackageMultipleVersions.active? ? "target_version_id" : "version_id")
  end

  def self.translate(value, interchangeable_names, target_name)
    return value if interchangeable_names.exclude?(value.to_s)

    target_name
  end
  private_class_method :translate
end

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

class Setting
  # Single gate for the "multiple (target) versions" feature. Every call site
  # (views, contracts, services) should ask this predicate rather than reading
  # the flag or the setting directly, so the feature can be rolled out in phases
  # by changing only this method.
  #
  # The user-facing Setting.work_package_multiple_versions is already respected,
  # but the experimental feature flag takes precedence: while it is active (it is
  # on by default in development and can be toggled at /admin/settings/experimental)
  # the feature is enabled regardless of the setting. This lets a developer opt in
  # via the flag today, while the setting governs everywhere the flag is off.
  #
  #   * later (phase 2): build the admin switch for the setting; this predicate
  #     needs no change, as it already respects the setting.
  #   * before release (phase 3): drop the flag, leaving just
  #       Setting.work_package_multiple_versions?
  module WorkPackageMultipleVersions
    def self.active?
      OpenProject::FeatureDecisions.work_package_multiple_versions_active? ||
        Setting.work_package_multiple_versions?
    end
  end
end

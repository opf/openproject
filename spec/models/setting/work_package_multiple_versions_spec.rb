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

require "spec_helper"

RSpec.describe Setting::WorkPackageMultipleVersions do
  # The feature flag takes precedence: while it is active the feature is enabled
  # regardless of the setting.
  context "when the feature flag is active", with_flag: { work_package_multiple_versions: true } do
    context "and the setting is disabled", with_settings: { work_package_multiple_versions: false } do
      it { expect(described_class.active?).to be true }
    end
  end

  # With the flag off, the user-facing setting governs.
  context "when the feature flag is inactive", with_flag: { work_package_multiple_versions: false } do
    context "and the setting is enabled", with_settings: { work_package_multiple_versions: true } do
      it { expect(described_class.active?).to be true }
    end

    context "and the setting is disabled", with_settings: { work_package_multiple_versions: false } do
      it { expect(described_class.active?).to be false }
    end
  end
end

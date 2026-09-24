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

RSpec.describe WorkPackages::TrashFeature do
  describe ".enabled?" do
    it "is disabled without an entitlement or explicit preview opt-in" do
      expect(described_class).not_to be_enabled
    end

    it "is not enabled by an unrelated Enterprise entitlement", with_ee: %i[mcp_server] do
      expect(described_class).not_to be_enabled
    end

    it "is enabled by its Enterprise entitlement", with_ee: %i[work_package_trash] do
      expect(described_class).to be_enabled
    end

    it "can be enabled explicitly for prototype environments",
       with_env: { "OPENPROJECT_ENABLE_WORK_PACKAGE_TRASH" => "true" } do
      expect(described_class).to be_enabled
    end
  end
end

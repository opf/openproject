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
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require "spec_helper"

RSpec.describe OpenProject::AccessControl do
  describe "SquashTM permissions" do
    it "are part of the squashtm project module" do
      %i[manage_squashtm_integration].each do |name|
        expect(described_class.permission(name).project_module).to be(:squashtm)
      end
    end

    it "are only available on projects" do
      %i[manage_squashtm_integration].each do |name|
        expect(described_class.permission(name).permissible_on).to contain_exactly(:project)
      end
    end

    it "can only be granted to members for managing the integration" do
      expect(described_class.permission(:manage_squashtm_integration)).to be_require_member
    end
  end

  describe "squashtm project module" do
    it "depends on the work package tracking module" do
      mod = described_class.modules.find { |m| m[:name] == :squashtm }

      expect(mod[:dependencies]).to contain_exactly(:work_package_tracking)
    end
  end
end

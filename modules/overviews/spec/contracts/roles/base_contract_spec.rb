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
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Roles::BaseContract do
  let(:work_package_role) { build_stubbed(:work_package_role) }
  let(:member_role) { build_stubbed(:project_role) }
  let(:global_role) { build_stubbed(:global_role) }
  let(:anonymous_role) { build_stubbed(:anonymous_role) }
  let(:current_user) { build_stubbed(:admin) }
  let(:contract) { described_class.new(role, current_user) }

  describe "assignable_permissions" do
    context "for a work package role" do
      let(:role) { work_package_role }

      it "does not include manage_dashboards" do
        expect(contract.assignable_permissions.map(&:name))
          .not_to include :manage_dashboards
      end
    end

    context "for a member role" do
      let(:role) { member_role }

      it "includes manage_dashboards" do
        expect(contract.assignable_permissions.map(&:name))
          .to include :manage_dashboards
      end
    end

    context "for a global role" do
      let(:role) { global_role }

      it "does not include manage_dashboards" do
        expect(contract.assignable_permissions.map(&:name))
          .not_to include :manage_dashboards
      end
    end

    context "for a builtin role" do
      let(:role) { anonymous_role }

      it "does not include manage_dashboards" do
        expect(contract.assignable_permissions.map(&:name))
          .not_to include :manage_dashboards
      end
    end
  end
end

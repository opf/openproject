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

RSpec.describe SquashTMIntegration::WorkPackageTabState do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { [] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  subject(:state) { described_class.new(work_package:, user:) }

  describe "#status" do
    it "is :no_server without a configured server" do
      expect(state.status).to eq(:no_server)
    end

    context "with a configured server" do
      before { create(:squashtm_server) }

      it "is :project_not_linked when the project is not linked" do
        expect(state.status).to eq(:project_not_linked)
      end

      it "is :not_linked when the project is linked" do
        create(:squashtm_project_link, project:)

        expect(state.status).to eq(:not_linked)
      end
    end
  end

  describe "#can_configure_server?" do
    it "is false for a non-admin" do
      expect(state).not_to be_can_configure_server
    end

    context "for an administrator" do
      let(:user) { create(:admin) }

      it { is_expected.to be_can_configure_server }
    end
  end

  describe "#can_manage_project_link?" do
    it "is false without the permission" do
      expect(state).not_to be_can_manage_project_link
    end

    context "with the permission to manage the integration" do
      let(:permissions) { %i[view_work_packages manage_squashtm_integration] }

      it { is_expected.to be_can_manage_project_link }
    end
  end
end

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

      it "is :linked when a requirement is linked" do
        create(:squashtm_project_link, project:)
        create(:squashtm_work_package_link, work_package:)

        expect(state.status).to eq(:linked)
      end
    end
  end

  describe "#can_manage_links?" do
    it "is false without the permission" do
      expect(state).not_to be_can_manage_links
    end

    context "with the permission to manage requirement links" do
      let(:permissions) { %i[view_work_packages manage_squashtm_links] }

      it { is_expected.to be_can_manage_links }
    end
  end

  describe "#requirement" do
    let(:client) { instance_double(SquashTMIntegration::Client) }
    let(:coverage) { instance_double(SquashTMIntegration::RequirementCoverage) }
    let(:work_package_link) { create(:squashtm_work_package_link, work_package:, squashtm_requirement_id: 11) }

    subject(:state) { described_class.new(work_package:, user:, work_package_link:) }

    before do
      create(:squashtm_server)
      allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
      allow(SquashTMIntegration::RequirementCoverage).to receive(:new).with(client).and_return(coverage)
    end

    it "loads the requirement with its test cases" do
      requirement = instance_double(SquashTMIntegration::RequirementCoverage::Requirement)
      allow(coverage).to receive(:call).with(11).and_return(requirement)

      expect(state.requirement).to eq(requirement)
      expect(state.requirement_error).to be_nil
    end

    it "reports :not_found when the requirement no longer exists" do
      allow(coverage).to receive(:call).and_raise(SquashTMIntegration::Client::NotFoundError)

      expect(state.requirement).to be_nil
      expect(state.requirement_error).to eq(:not_found)
    end

    it "reports :unavailable when SquashTM cannot be reached" do
      allow(coverage).to receive(:call).and_raise(SquashTMIntegration::Client::TimeoutError)

      expect(state.requirement).to be_nil
      expect(state.requirement_error).to eq(:unavailable)
    end
  end

  describe "#requirement_options" do
    let(:client) { instance_double(SquashTMIntegration::Client) }

    before do
      create(:squashtm_server)
      create(:squashtm_project_link, project:, squashtm_project_id: 3)
      allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    end

    it "lists the requirements of the linked SquashTM project sorted by name" do
      allow(client).to receive(:all_requirements).with(3).and_return(
        [{ "id" => 2, "name" => "b second", "extra" => 1 }, { "id" => 1, "name" => "A first" }]
      )

      expect(state.requirement_options).to eq([{ id: 1, name: "A first" }, { id: 2, name: "b second" }])
    end

    it "is nil when SquashTM cannot be reached" do
      allow(client).to receive(:all_requirements).and_raise(SquashTMIntegration::Client::TimeoutError)

      expect(state.requirement_options).to be_nil
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

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

RSpec.describe Members::DeleteByPrincipalService, type: :model do
  subject(:service_call) { instance.call(call_attributes) }

  let(:instance) { described_class.new(user:, project:, principal:) }
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:principal) { build_stubbed(:principal) }

  describe "#call" do
    context "when called without params" do
      let(:call_attributes) { {} }

      it { is_expected.to be_success }
    end

    context "when requested to delete project member" do
      let(:call_attributes) { { project: "✓" } }
      let!(:member) { create(:member, project:, principal:, member_roles: [build(:member_role)]) }
      let(:service_instance) { instance_double(Members::DeleteService, call: service_result) }
      let(:service_result) { ServiceResult.success }

      before do
        allow(Members::DeleteService)
          .to receive(:new)
          .with(user:, model: member)
          .and_return(service_instance)
      end

      it "calls Members::DeleteService" do
        service_call

        expect(service_instance).to have_received(:call).with(no_args)
      end

      context "when call succeeds" do
        it { is_expected.to be_success }
      end

      context "when call fails" do
        let(:service_result) { ServiceResult.failure }

        it { is_expected.not_to be_success }
      end
    end

    context "when requested to delete all work package shares" do
      let(:call_attributes) { { work_package_shares_role_id: "all" } }
      let(:work_package_a) { build(:work_package) }
      let(:work_package_b) { build(:work_package) }
      let(:work_package_c) { build(:work_package) }
      let!(:member_a) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role)],
               entity: work_package_a)
      end
      let!(:member_b) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role, inherited_from: 123)],
               entity: work_package_b)
      end
      let!(:member_c) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role), build(:member_role, inherited_from: 123)],
               entity: work_package_c)
      end
      let(:service_instance_a) { instance_double(Shares::DeleteService, call: service_result_a) }
      let(:service_instance_c) { instance_double(Shares::DeleteService, call: service_result_c) }
      let(:service_result_a) { ServiceResult.success }
      let(:service_result_c) { ServiceResult.success }

      before do
        allow(Shares::DeleteService)
          .to receive(:new)
          .with(user:, model: member_a, contract_class: Shares::WorkPackages::DeleteContract)
          .and_return(service_instance_a)
        allow(Shares::DeleteService)
          .to receive(:new)
          .with(user:, model: member_c, contract_class: Shares::WorkPackages::DeleteContract)
          .and_return(service_instance_c)
      end

      it "calls Members::DeleteService for every member that has non inherited roles" do
        service_call

        expect(service_instance_a).to have_received(:call).with(no_args)
        expect(Shares::DeleteService)
          .not_to have_received(:new)
          .with(user:, model: member_b, contract_class: Shares::WorkPackages::DeleteContract)
        expect(service_instance_c).to have_received(:call).with(no_args)
      end

      context "when all calls succeed" do
        it { is_expected.to be_success }
      end

      context "when at least one call fails" do
        let(:service_result_c) { ServiceResult.failure }

        it { is_expected.not_to be_success }
      end
    end

    context "when requested to delete work package shares with specific role id" do
      let(:call_attributes) { { work_package_shares_role_id: role.id.to_s } }
      let(:work_package_a) { build(:work_package) }
      let(:work_package_b) { build(:work_package) }
      let(:work_package_c) { build(:work_package) }
      let(:work_package_d) { build(:work_package) }
      let(:role) { create(:work_package_role) }
      let!(:member_a) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role, role:)],
               entity: work_package_a)
      end
      let!(:member_b) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role, role:, inherited_from: 123)],
               entity: work_package_b)
      end
      let!(:member_c) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role, role:), build(:member_role, role:, inherited_from: 123)],
               entity: work_package_c)
      end
      let!(:member_d) do
        create(:member,
               project:,
               principal:,
               member_roles: [build(:member_role)],
               entity: work_package_d)
      end
      let(:service_instance_a) { instance_double(Shares::DeleteRoleService, call: service_result_a) }
      let(:service_instance_c) { instance_double(Shares::DeleteRoleService, call: service_result_c) }
      let(:service_result_a) { ServiceResult.success }
      let(:service_result_c) { ServiceResult.success }

      before do
        allow(Shares::DeleteRoleService)
          .to receive(:new)
          .with(user:, model: member_a, contract_class: Shares::WorkPackages::DeleteContract)
          .and_return(service_instance_a)
        allow(Shares::DeleteRoleService)
          .to receive(:new)
          .with(user:, model: member_c, contract_class: Shares::WorkPackages::DeleteContract)
          .and_return(service_instance_c)
      end

      it "calls Members::DeleteService for every member that has non inherited role with specific role id" do
        service_call

        expect(service_instance_a).to have_received(:call).with(role_id: role.id.to_s)
        expect(Shares::DeleteRoleService)
          .not_to have_received(:new)
          .with(user:, model: member_b, contract_class: Shares::WorkPackages::DeleteContract)
        expect(service_instance_c).to have_received(:call).with(role_id: role.id.to_s)
        expect(Shares::DeleteRoleService)
          .not_to have_received(:new)
          .with(user:, model: member_d, contract_class: Shares::WorkPackages::DeleteContract)
      end

      context "when all calls succeed" do
        it { is_expected.to be_success }
      end

      context "when at least one call fails" do
        let(:service_result_c) { ServiceResult.failure }

        it { is_expected.not_to be_success }
      end
    end
  end
end

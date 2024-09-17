# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require "services/base_services/behaves_like_delete_service"

RSpec.describe Shares::DeleteRoleService, type: :model do
  it_behaves_like "BaseServices delete service" do
    let(:factory) { :work_package_member }
    let(:model_class) { Member }
    let(:model_instance) { build_stubbed(:work_package_member, principal:) }
    let(:principal) { user }

    let!(:cleanup_service_instance) do
      instance_double(Members::CleanupService, call: nil).tap do |service_double|
        allow(Members::CleanupService)
          .to receive(:new)
                .with(principal, model_instance.project_id)
                .and_return(service_double)
      end
    end

    describe "#call" do
      context "when contract validates and the model is destroyed successfully" do
        it "calls the cleanup service" do
          service_call

          expect(cleanup_service_instance)
            .to have_received(:call)
        end

        context "when the model's principal is a group" do
          let(:principal) { build_stubbed(:group) }
          let!(:cleanup_inherited_roles_service_instance) do
            instance_double(Groups::CleanupInheritedRolesService, call: nil).tap do |service_double|
              allow(Groups::CleanupInheritedRolesService)
                .to receive(:new)
                      .with(principal,
                            current_user: user,
                            contract_class: EmptyContract)
                      .and_return(service_double)
            end
          end

          it "calls the cleanup inherited roles service" do
            service_call

            expect(cleanup_inherited_roles_service_instance)
              .to have_received(:call)
          end
        end
      end

      context "when member has multiple member roles" do
        let(:selected_member_role) { build(:member_role) }
        let(:other_member_role) { build(:member_role) }
        let(:member_roles) { [selected_member_role, other_member_role] }
        let!(:model_instance) { create(factory, principal:, member_roles:) }
        let(:call_attributes) { { role_id: selected_member_role.role_id } }

        it "does not destroy the member" do
          service_call

          expect(model_instance).not_to have_received(:destroy)
        end

        it "does not destroy non selected member role" do
          service_call

          expect { other_member_role.reload }.not_to raise_error
        end

        it "destroys the selected member role" do
          service_call

          expect { selected_member_role.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "is successful" do
          expect(subject).to be_success
        end
      end

      context "when member has inherited member role" do
        let(:direct_member_role) { build(:member_role) }
        let(:inherited_member_role) { build(:member_role, inherited_from: 123) }
        let(:member_roles) { [direct_member_role, inherited_member_role] }
        let!(:model_instance) { create(factory, principal:, member_roles:) }
        let(:call_attributes) { { role_id: direct_member_role.role_id } }

        it "does not destroy the member" do
          service_call

          expect(model_instance).not_to have_received(:destroy)
        end

        it "does not destroy inherited member role" do
          service_call

          expect { inherited_member_role.reload }.not_to raise_error
        end

        it "destroys direct member role" do
          service_call

          expect { direct_member_role.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "is successful" do
          expect(subject).to be_success
        end
      end
    end
  end
end

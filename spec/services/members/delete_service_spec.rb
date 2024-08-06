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
require "services/base_services/behaves_like_delete_service"

RSpec.describe Members::DeleteService, type: :model do
  it_behaves_like "BaseServices delete service" do
    let(:principal) { user }
    before do
      model_instance.principal = principal

      allow(model_instance).to receive(:destroy) do
        allow(model_instance).to receive(:destroyed?).and_return(model_destroy_result)

        model_destroy_result
      end

      allow(OpenProject::Notifications)
        .to receive(:send)
    end

    let!(:cleanup_service_instance) do
      instance = instance_double(Members::CleanupService, call: nil)

      allow(Members::CleanupService)
        .to receive(:new)
        .with(principal, model_instance.project_id)
        .and_return(instance)

      instance
    end

    describe "#call" do
      context "when contract validates and the model is destroyed successfully" do
        it "calls the cleanup service" do
          service_call

          expect(cleanup_service_instance)
            .to have_received(:call)
        end

        it "sends a notification" do
          service_call

          expect(OpenProject::Notifications)
            .to have_received(:send)
            .with(OpenProject::Events::MEMBER_DESTROYED, member: model_instance)
        end

        context "when the model`s principal is a group" do
          let(:principal) { build_stubbed(:group) }
          let!(:cleanup_inherited_roles_service_instance) do
            instance = instance_double(Groups::CleanupInheritedRolesService, call: nil)

            allow(Groups::CleanupInheritedRolesService)
              .to receive(:new)
              .with(principal,
                    current_user: user,
                    contract_class: EmptyContract)
              .and_return(instance)

            instance
          end

          it "calls the cleanup inherited roles service" do
            service_call

            expect(cleanup_inherited_roles_service_instance)
              .to have_received(:call)
          end
        end
      end

      context "when member has inherited member_roles" do
        let(:direct_member_role_a) { build(:member_role) }
        let(:direct_member_role_b) { build(:member_role) }
        let(:inherited_member_role) { build(:member_role, inherited_from: 123) }
        let(:member_roles) { [direct_member_role_a, direct_member_role_b, inherited_member_role] }
        let!(:model_instance) { create(factory, member_roles:) }

        it "does not destroy the member" do
          service_call

          expect(model_instance).not_to have_received(:destroy)
        end

        it "does not destroy inherited member roles" do
          service_call

          expect { inherited_member_role.reload }.not_to raise_error
        end

        it "destroys direct member roles" do
          service_call

          expect { direct_member_role_a.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { direct_member_role_b.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "is successful" do
          expect(subject).to be_success
        end

        it "calls the cleanup service" do
          service_call

          expect(cleanup_service_instance)
            .to have_received(:call)
        end

        it "doesn't send a notification" do
          service_call

          expect(OpenProject::Notifications).not_to have_received(:send)
        end
      end
    end
  end
end

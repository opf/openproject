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
require "services/base_services/behaves_like_update_service"

RSpec.describe Members::UpdateService, type: :model do
  let(:user1) { build_stubbed(:user) }
  let(:user2) { build_stubbed(:user) }
  let(:child_group) do
    build_stubbed(:group).tap do |g|
      allow(g).to receive(:user_ids).and_return([user2.id])
    end
  end
  let(:group) do
    build_stubbed(:group).tap do |g|
      allow(g).to receive_messages(user_ids: [user1.id], self_and_descendants: [g, child_group])
    end
  end
  let!(:update_roles_service) do
    instance_double(Groups::UpdateRolesService).tap do |service|
      allow(Groups::UpdateRolesService)
        .to receive(:new)
              .and_return(service)

      allow(service)
        .to receive(:call)
    end
  end
  let!(:notifications) do
    allow(OpenProject::Notifications)
      .to receive(:send)
  end

  it_behaves_like "BaseServices update service" do
    let(:call_attributes) do
      {
        role_ids: ["2"],
        notification_message: "Wish you where **here**.",
        send_notifications: false
      }
    end

    describe "if successful" do
      it "sends a notification" do
        subject

        expect(OpenProject::Notifications)
          .to have_received(:send)
          .with(OpenProject::Events::MEMBER_UPDATED,
                member: model_instance,
                message: call_attributes[:notification_message],
                send_notifications: call_attributes[:send_notifications])
      end

      describe "for a group" do
        let!(:model_instance) { build_stubbed(:member, principal: group) }

        it "calls UpdateRolesService with user_ids from self_and_descendants" do
          subject

          expect(Groups::UpdateRolesService)
            .to have_received(:new)
                  .with(group, current_user: user, contract_class: EmptyContract)

          expect(update_roles_service)
            .to have_received(:call)
                  .with(member: model_instance,
                        user_ids: [user1.id, user2.id],
                        send_notifications: call_attributes[:send_notifications],
                        message: call_attributes[:notification_message])
        end

        it "does not send a notification" do
          subject

          expect(OpenProject::Notifications)
            .not_to have_received(:send)
        end
      end
    end

    context "if the SetAttributeService is unsuccessful" do
      let(:set_attributes_success) { false }

      it "sends no notifications" do
        subject

        expect(OpenProject::Notifications)
          .not_to have_received(:send)
      end

      describe "for a group" do
        let!(:model_instance) { build_stubbed(:member, principal: group) }

        it "does not call UpdateRolesService" do
          subject

          expect(Groups::UpdateRolesService)
            .not_to have_received(:new)
        end
      end
    end

    context "when the member is invalid" do
      let(:model_save_result) { false }

      it "sends no notifications" do
        subject

        expect(OpenProject::Notifications)
          .not_to have_received(:send)
      end

      context "for a group" do
        let!(:model_instance) { build_stubbed(:member, principal: group) }

        it "does not call UpdateRolesService" do
          subject

          expect(Groups::UpdateRolesService)
            .not_to have_received(:new)
        end
      end
    end
  end
end

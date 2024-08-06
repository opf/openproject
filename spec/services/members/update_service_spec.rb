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
  it_behaves_like "BaseServices update service" do
    let(:call_attributes) do
      {
        role_ids: ["2"],
        notification_message: "Wish you where **here**.",
        send_notifications: false
      }
    end

    before do
      allow(OpenProject::Notifications)
        .to receive(:send)
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
    end

    context "if the SetAttributeService is unsuccessful" do
      let(:set_attributes_success) { false }

      it "sends no notifications" do
        subject

        expect(OpenProject::Notifications)
          .not_to have_received(:send)
      end
    end

    context "when the member is invalid" do
      let(:model_save_result) { false }

      it "sends no notifications" do
        subject

        expect(OpenProject::Notifications)
          .not_to have_received(:send)
      end
    end
  end
end

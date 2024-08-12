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

RSpec.describe API::V3::Memberships::MembershipPayloadRepresenter do
  let(:membership) { build_stubbed(:member) }

  current_user { build_stubbed(:user) }

  describe "generation" do
    subject(:json) { representer.to_json }

    describe "_meta" do
      describe "notificationMessage" do
        let(:meta) { OpenStruct.new notifiation_message: "Come to the dark side" }
        let(:representer) do
          described_class.create(membership,
                                 meta:,
                                 current_user:)
        end

        it_behaves_like "formattable property", :"_meta/notificationMessage" do
          let(:value) { meta.notification_message }
        end
      end

      describe "sendNotifications" do
        let(:meta) { OpenStruct.new send_notifications: true }
        let(:representer) do
          described_class.create(membership,
                                 meta:,
                                 current_user:)
        end

        it_behaves_like "property", :"_meta/sendNotifications" do
          let(:value) { true }
        end
      end
    end
  end

  describe "parsing" do
    subject(:parsed) { representer.from_hash parsed_hash }

    let(:representer) do
      described_class.create(OpenStruct.new,
                             meta: OpenStruct.new,
                             current_user:)
    end

    describe "_meta" do
      context "with meta set" do
        let(:parsed_hash) do
          {
            "_meta" => {
              "notificationMessage" => {
                "raw" => "Come to the dark side"
              },
              "sendNotifications" => true
            }
          }
        end

        it "sets the parsed message" do
          expect(parsed.meta.notification_message)
            .to eql "Come to the dark side"
        end

        it "sets the notification sending configuration" do
          expect(parsed.meta.send_notifications)
            .to be_truthy
        end
      end
    end
  end
end

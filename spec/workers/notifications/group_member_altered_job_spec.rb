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

RSpec.describe Notifications::GroupMemberAlteredJob, type: :model do
  subject(:service_call) do
    described_class.new.perform(current_user, members_ids, message, send_notification)
  end

  let(:current_user) { build_stubbed(:user) }
  let(:time) { Time.now }
  let(:member1) do
    build_stubbed(:member, updated_at: time, created_at: time)
  end
  let(:member2) do
    build_stubbed(:member, updated_at: time + 1.second, created_at: time)
  end
  let(:members) { [member1, member2] }
  let(:members_ids) { members.map(&:id) }
  let(:message) { "Some message" }
  let(:send_notification) { false }

  before do
    allow(OpenProject::Notifications)
      .to receive(:send)

    allow(Member)
      .to receive(:where)
      .with(id: members_ids)
      .and_return(members)
  end

  it "sends a created notification for the membership with the matching timestamps" do
    service_call

    expect(OpenProject::Notifications)
      .to have_received(:send)
      .with(OpenProject::Events::MEMBER_CREATED, member: member1, message:, send_notifications: send_notification)
  end

  it "sends an updated notification for the membership with the mismatching timestamps" do
    service_call

    expect(OpenProject::Notifications)
      .to have_received(:send)
      .with(OpenProject::Events::MEMBER_UPDATED, member: member2, message:, send_notifications: send_notification)
  end

  it "propagates the given current user when sending notifications" do
    captured_current_user = nil
    allow(OpenProject::Notifications)
      .to receive(:send) do |_args|
        captured_current_user = User.current
      end

    service_call
    expect(captured_current_user).to be(current_user)
  end
end

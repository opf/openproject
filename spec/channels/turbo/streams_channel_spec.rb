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

RSpec.describe Turbo::StreamsChannel, "subscription authorization" do
  shared_let(:project) { create(:project, public: false) }
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  def subscribe_to(record, current_user:)
    stub_connection(current_user:, session_private_id: "session-1")
    subscribe(signed_stream_name: described_class.signed_stream_name(record))
  end

  it "confirms subscriptions to records the user can see" do
    subscribe_to(project, current_user: admin)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(project.to_gid_param)
  end

  it "rejects subscriptions to records the user cannot see, although the name is signed" do
    subscribe_to(project, current_user: user)

    expect(subscription).to be_rejected
  end

  it "rejects forged stream names" do
    stub_connection(current_user: admin)
    subscribe(signed_stream_name: "forged--signature")

    expect(subscription).to be_rejected
  end

  describe "tracking subscriptions for re-authorization" do
    it "records a granted subscription" do
      subscribe_to(project, current_user: admin)

      expect(LiveUpdatesSubscription.where(user: admin, session_id: "session-1", stream_name: project.to_gid_param))
        .to be_one
    end

    it "does not record a rejected subscription" do
      subscribe_to(project, current_user: user)

      expect(LiveUpdatesSubscription.count).to be_zero
    end

    it "keeps the records of the user's open subscriptions when rejecting another" do
      LiveUpdatesSubscription.create!(user:, session_id: "session-1", stream_name: project.to_gid_param)
      subscribe_to(project, current_user: user)

      expect(subscription).to be_rejected
      expect(LiveUpdatesSubscription.where(user:, stream_name: project.to_gid_param))
        .to be_one
    end

    it "removes only its own record on unsubscribe, keeping those of the session's other tabs" do
      LiveUpdatesSubscription.create!(user: admin, session_id: "session-1", stream_name: project.to_gid_param)
      subscribe_to(project, current_user: admin)
      unsubscribe

      expect(LiveUpdatesSubscription.where(user: admin, session_id: "session-1", stream_name: project.to_gid_param))
        .to be_one
    end

    it "keeps the records of the user's other sessions on unsubscribe" do
      LiveUpdatesSubscription.create!(user: admin, session_id: "session-2", stream_name: project.to_gid_param)
      subscribe_to(project, current_user: admin)
      LiveUpdatesSubscription.where(session_id: "session-1").delete_all
      unsubscribe

      expect(LiveUpdatesSubscription.where(user: admin, session_id: "session-2")).to be_one
    end
  end
end

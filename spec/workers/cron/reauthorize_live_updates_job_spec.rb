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

RSpec.describe Cron::ReauthorizeLiveUpdatesJob, type: :job do
  shared_let(:project) { create(:project, public: false) }
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  let(:stream_name) { project.to_gid_param }
  let(:session_id) { create(:user_session).session_id }
  let(:checked_at) { (described_class::RECHECK_AFTER + 1.minute).ago }

  before do
    allow(OpenProject::LiveUpdates).to receive_messages(enabled?: enabled, reauthorize: nil)
  end

  context "when live updates are enabled" do
    let(:enabled) { true }

    it "reconnects users who lost access to a subscribed stream, keeping the row until they unsubscribe" do
      LiveUpdatesSubscription.create!(user:, session_id:, stream_name:, updated_at: checked_at)

      described_class.perform_now

      expect(OpenProject::LiveUpdates).to have_received(:reauthorize).with(contain_exactly(user))
      expect(LiveUpdatesSubscription.count).to eq(1)
    end

    it "keeps subscriptions that are still allowed, marking them as checked" do
      subscription = LiveUpdatesSubscription.create!(user: admin, session_id:, stream_name:, updated_at: checked_at)

      described_class.perform_now

      expect(OpenProject::LiveUpdates).not_to have_received(:reauthorize)
      expect(LiveUpdatesSubscription.count).to eq(1)
      expect(subscription.reload.updated_at).to be > checked_at
    end

    it "does not recheck subscriptions checked recently" do
      subscription = LiveUpdatesSubscription.create!(user:, session_id:, stream_name:, updated_at: 1.minute.ago)

      expect { described_class.perform_now }.not_to change { subscription.reload.updated_at }
      expect(OpenProject::LiveUpdates).not_to have_received(:reauthorize)
    end

    it "reconnects the users of stale subscriptions so they are recorded afresh" do
      LiveUpdatesSubscription.create!(user: admin, session_id:, stream_name:,
                                      created_at: (described_class::STALE_AFTER + 1.minute).ago)

      described_class.perform_now

      expect(OpenProject::LiveUpdates).to have_received(:reauthorize).with(contain_exactly(admin))
      expect(LiveUpdatesSubscription.count).to eq(0)
    end

    it "reconnects the users of subscriptions whose session ended, removing those" do
      LiveUpdatesSubscription.create!(user: admin, session_id: "logged-out", stream_name:)

      described_class.perform_now

      expect(OpenProject::LiveUpdates).to have_received(:reauthorize).with(contain_exactly(admin))
      expect(LiveUpdatesSubscription.count).to eq(0)
    end

    it "reconnects a user once, although several checks fail" do
      LiveUpdatesSubscription.create!(user:, session_id: "logged-out", stream_name:, updated_at: checked_at,
                                      created_at: (described_class::STALE_AFTER + 1.minute).ago)

      described_class.perform_now

      expect(OpenProject::LiveUpdates).to have_received(:reauthorize).once.with(contain_exactly(user))
    end

    context "with a session TTL", with_settings: { session_ttl_enabled?: true, session_ttl: "120" } do
      it "reconnects the users of subscriptions whose session exceeded the TTL, removing those" do
        LiveUpdatesSubscription.create!(user: admin, session_id:, stream_name:)

        travel 3.hours do
          described_class.perform_now
        end

        expect(OpenProject::LiveUpdates).to have_received(:reauthorize).with(contain_exactly(admin))
        expect(LiveUpdatesSubscription.count).to eq(0)
      end
    end
  end

  context "when live updates are not enabled" do
    let(:enabled) { false }

    it "does nothing" do
      LiveUpdatesSubscription.create!(user:, session_id:, stream_name:)

      described_class.perform_now

      expect(OpenProject::LiveUpdates).not_to have_received(:reauthorize)
      expect(LiveUpdatesSubscription.count).to eq(1)
    end
  end
end

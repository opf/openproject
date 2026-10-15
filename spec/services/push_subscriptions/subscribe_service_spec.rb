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

RSpec.describe PushSubscriptions::SubscribeService do
  def session_row_for(owner)
    Sessions::UserSession.find_by!(session_id: create(:user_session, user: owner).session_id)
  end

  let(:user) { create(:user) }
  let(:session_row) { session_row_for(user) }
  let(:endpoint) { "https://fcm.googleapis.com/fcm/send/abc123" }
  let(:device) { { browser_name: "Firefox", browser_version: "140", platform: "Linux" } }
  let(:service) { described_class.new(user:, session_id: session_row.id, device:) }

  describe "#call" do
    it "binds a new endpoint to the user and session with the device snapshot" do
      result = service.call(endpoint:)

      expect(result).to be_success
      expect(result.result).to eq(PushSubscription.sole)
      expect(PushSubscription.sole)
        .to have_attributes(user:, endpoint:, session: session_row,
                            browser_name: "Firefox", browser_version: "140", platform: "Linux")
    end

    it "moves an endpoint stored for an older session of the same user to the current session" do
      existing = create(:push_subscription, user:, session: session_row_for(user), endpoint:)

      expect { service.call(endpoint:) }.not_to change(PushSubscription, :count)

      expect(existing.reload.session).to eq(session_row)
    end

    it "replaces this session's subscription when a new endpoint comes" do
      stale = create(:push_subscription, user:, session: session_row)

      service.call(endpoint:)

      expect(PushSubscription.where(session: session_row)).to contain_exactly(have_attributes(endpoint:))
      expect(PushSubscription.exists?(stale.id)).to be(false)
    end

    it "keeps this session's subscription when the new endpoint is rejected" do
      stale = create(:push_subscription, user:, session: session_row)

      result = service.call(endpoint: "https://evil.example/x")

      expect(result).to be_failure
      expect(PushSubscription.exists?(stale.id)).to be(true)
    end

    it "refuses an endpoint held by another user's active subscription" do
      existing = create(:push_subscription, endpoint:)

      result = service.call(endpoint:)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:endpoint)).to eq([:taken])
      expect(existing.reload.user).not_to eq(user)
    end

    it "takes over another user's dormant row on a shared browser" do
      previous = create(:push_subscription, endpoint:, session: nil)

      result = service.call(endpoint:)

      expect(result).to be_success
      expect(PushSubscription.exists?(previous.id)).to be(false)
      expect(PushSubscription.sole).to have_attributes(user:, endpoint:, session: session_row)
    end

    it "refuses the takeover when the other user resumed the row in the meantime" do
      previous = create(:push_subscription, endpoint:, session: nil)
      allow(PushSubscription).to receive(:dormant).and_return(PushSubscription.none)

      result = service.call(endpoint:)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:endpoint)).to eq([:taken])
      expect(PushSubscription.sole).to eq(previous)
    end

    it "retries once when a concurrent request stored the endpoint first" do
      existing = create(:push_subscription, user:, endpoint:)
      calls = 0
      allow(PushSubscriptions::CreateService).to receive(:new).and_wrap_original do |original, **args|
        original.call(**args).tap do |create_service|
          allow(create_service).to receive(:call).and_wrap_original do |call, **kwargs|
            calls += 1
            raise ActiveRecord::RecordNotUnique if calls == 1

            call.call(**kwargs)
          end
        end
      end

      result = service.call(endpoint:)

      expect(result).to be_success
      expect(calls).to eq(2)
      expect(existing.reload.user).to eq(user)
    end

    context "when resuming" do
      it "rebinds a dormant row of the user and clears its suspension" do
        dormant = create(:push_subscription, user:, endpoint:, session: nil, suspended_at: 2.days.ago)

        result = service.call(endpoint:, resume: true)

        expect(result).to be_success
        expect(dormant.reload).to have_attributes(session: session_row, suspended_at: nil)
      end

      it "succeeds with no result and writes nothing when the user has no row for the endpoint" do
        other = create(:push_subscription, endpoint:, session: nil)

        result = service.call(endpoint:, resume: true)

        expect(result).to be_success
        expect(result.result).to be_nil
        expect(PushSubscription.sole).to eq(other)
        expect(other.reload.session_id).to be_nil
      end
    end
  end
end

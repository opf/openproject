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
require "contracts/shared/model_contract_shared_context"

RSpec.describe PushSubscriptions::CreateContract do
  include_context "ModelContract shared context"

  let(:current_user) { create(:user) }
  let(:endpoint) { "https://fcm.googleapis.com/fcm/send/abc" }
  let(:model_user) { current_user }
  let(:session) { Sessions::UserSession.find_by!(session_id: create(:user_session, user: current_user).session_id) }
  let(:subscription) { PushSubscription.new(user: model_user, session_id: session.id, endpoint:) }
  let(:contract) { described_class.new(subscription, current_user) }

  [
    "https://fcm.googleapis.com/fcm/send/abc",
    "https://updates.push.services.mozilla.com/wpush/v2/abc",
    "https://db5p.notify.windows.com/w/?token=abc",
    "https://web.push.apple.com/abc"
  ].each do |valid_endpoint|
    context "with the endpoint #{valid_endpoint}" do
      let(:endpoint) { valid_endpoint }

      it_behaves_like "contract is valid"
    end
  end

  context "with a subdomain of an operator-added host",
          with_settings: { web_push_service_hosts: %w[push.example.com] } do
    let(:endpoint) { "https://eu.push.example.com/abc" }

    it_behaves_like "contract is valid"
  end

  context "with an endpoint of exactly the maximum length" do
    let(:endpoint) { "https://fcm.googleapis.com/".ljust(described_class::MAX_ENDPOINT_LENGTH, "a") }

    it_behaves_like "contract is valid"
  end

  [
    "http://fcm.googleapis.com/x",
    "https://fcm.googleapis.com:8443/x",
    "https://user@fcm.googleapis.com/x",
    "https://fcm.googleapis.com.evil.example/x",
    "https://evil.example/?x=fcm.googleapis.com",
    "https://fcm.googleapis.com/#{'a' * described_class::MAX_ENDPOINT_LENGTH}",
    "https://.push.apple.com/x",
    "https://.notify.windows.com/x",
    "not a url",
    "https:/x",
    "https://"
  ].each do |invalid_endpoint|
    context "with the endpoint #{invalid_endpoint.truncate(60)}" do
      let(:endpoint) { invalid_endpoint }

      it_behaves_like "contract is invalid", endpoint: :invalid
    end
  end

  context "when the subscription belongs to another user" do
    let(:model_user) { create(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "when the session belongs to another user" do
    let(:session) do
      Sessions::UserSession.find_by!(session_id: create(:user_session, user: create(:user)).session_id)
    end

    it_behaves_like "contract is invalid", session_id: :invalid
  end

  context "when the subscription has no session" do
    let(:subscription) { PushSubscription.new(user: model_user, endpoint:) }

    it_behaves_like "contract is invalid", session_id: :blank
  end

  context "when the user already holds the maximum number of subscriptions" do
    before { create_list(:push_subscription, PushSubscription::MAX_PER_USER, user: current_user) }

    it_behaves_like "contract is invalid", base: :too_many_push_subscriptions
  end

  context "when the user also holds signed out subscriptions beyond the maximum" do
    before do
      create_list(:push_subscription, PushSubscription::MAX_PER_USER, user: current_user, session: nil)
    end

    it_behaves_like "contract is valid"
  end

  context "when the user holds one fewer than the maximum" do
    before { create_list(:push_subscription, PushSubscription::MAX_PER_USER - 1, user: current_user) }

    it_behaves_like "contract is valid"
  end

  context "when re-saving one of the maximum number of subscriptions" do
    let(:subscription) do
      create_list(:push_subscription, PushSubscription::MAX_PER_USER, user: current_user).first
    end

    it_behaves_like "contract is valid"
  end

  include_examples "contract reuses the model errors"
end

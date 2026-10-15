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

RSpec.describe "My::PushSubscriptionsController",
               :skip_csrf,
               type: :rails_request,
               with_flag: { progressive_web_app: true },
               with_settings: { web_push_enabled: true } do
  let(:password) { "Sup3rS3cret!pass" }
  let(:user) { create(:user, password:, password_confirmation: password) }
  let(:endpoint) { "https://fcm.googleapis.com/fcm/send/abc123" }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:revoked_message) { I18n.t("my_account.push_notifications.revoked") }
  let(:json_headers) { turbo_headers.merge("CONTENT_TYPE" => "application/json") }

  def sign_in
    host! Setting.host_name
    post "/login", params: { username: user.login, password: }
    follow_redirect! while response.redirect?
    expect(request.session[:user_id]).to eq(user.id)
  end

  def current_session_row
    Sessions::UserSession.find_by!(session_id: request.session.id.private_id)
  end

  def subscribe(value)
    post "/my/push_subscriptions", params: { push_endpoint: value }.to_json, headers: json_headers
  end

  describe "POST /my/push_subscriptions" do
    context "when not signed in" do
      it "is unauthorized and stores nothing" do
        subscribe(endpoint)

        expect(response).to have_http_status(:unauthorized)
        expect(PushSubscription.count).to eq(0)
      end
    end

    context "when signed in" do
      before { sign_in }

      it "binds a new subscription to the current user and session and replaces the component" do
        subscribe(endpoint)

        expect(response).to have_http_status(:ok)
        assert_select "turbo-stream[action=replace][target=my-push-subscriptions]"
        expect(PushSubscription.sole).to have_attributes(user:, endpoint:, session: current_session_row)
      end

      it "snapshots the browser and platform of the current session" do
        subscribe(endpoint)

        expect(PushSubscription.sole)
          .to have_attributes(browser_name: request.session[:browser],
                              browser_version: request.session[:browser_version],
                              platform: request.session[:platform])
        expect(PushSubscription.sole.browser_name).to be_present
      end

      it "refuses an endpoint held by another user" do
        existing = create(:push_subscription, endpoint:)

        subscribe(endpoint)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
        expect(existing.reload.user).not_to eq(user)
      end

      it "moves an endpoint stored for an older session of the same user to the current session" do
        older = Sessions::UserSession.find_by!(session_id: create(:user_session, user:).session_id)
        existing = create(:push_subscription, user:, session: older, endpoint:)

        expect { subscribe(endpoint) }.not_to change(PushSubscription, :count)

        expect(existing.reload.session).to eq(current_session_row)
      end

      it "replaces this session's subscription when the browser posts a new endpoint" do
        stale = create(:push_subscription, user:, session: current_session_row)

        subscribe(endpoint)

        expect(PushSubscription.where(session: current_session_row)).to contain_exactly(have_attributes(endpoint:))
        expect(PushSubscription.exists?(stale.id)).to be(false)
      end

      it "retries once when a concurrent request stored the endpoint first" do
        existing = create(:push_subscription, user:, endpoint:)
        calls = 0
        allow(PushSubscriptions::CreateService).to receive(:new).and_wrap_original do |original, **args|
          original.call(**args).tap do |service|
            allow(service).to receive(:call).and_wrap_original do |call, **kwargs|
              calls += 1
              raise ActiveRecord::RecordNotUnique if calls == 1

              call.call(**kwargs)
            end
          end
        end

        subscribe(endpoint)

        expect(response).to have_http_status(:ok)
        expect(calls).to eq(2)
        expect(existing.reload.user).to eq(user)
      end

      it "keeps this session's subscription when the new endpoint is rejected" do
        stale = create(:push_subscription, user:, session: current_session_row)

        subscribe("https://evil.example/x")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(PushSubscription.exists?(stale.id)).to be(true)
      end

      it "rejects an endpoint that is not a push service" do
        subscribe("https://evil.example/x")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
        expect(PushSubscription.count).to eq(0)
      end

      [
        ["blank", ""],
        ["an array", ["https://fcm.googleapis.com/fcm/send/abc"]],
        ["a hash", { "url" => "https://fcm.googleapis.com/fcm/send/abc" }],
        ["longer than the maximum length", "https://fcm.googleapis.com/#{'a' * PushSubscriptions::BaseContract::MAX_ENDPOINT_LENGTH}"]
      ].each do |description, value|
        it "rejects an endpoint that is #{description} with a JSON error" do
          subscribe(value)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["errors"]).to be_present
          expect(PushSubscription.count).to eq(0)
        end
      end

      context "with the setting off", with_settings: { web_push_enabled: false } do
        it "is not found" do
          subscribe(endpoint)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "with forgery protection", skip_csrf: false do
      before do
        host! Setting.host_name
        get "/login"
        token = css_select("meta[name=csrf-token]").first["content"]
        post "/login", params: { username: user.login, password:, authenticity_token: token }
        follow_redirect! while response.redirect?
      end

      it "rejects a JSON request without the CSRF token" do
        subscribe(endpoint)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(PushSubscription.count).to eq(0)
      end
    end
  end

  describe "DELETE /my/push_subscriptions/:id" do
    let!(:subscription) { create(:push_subscription, user:) }

    context "when not signed in" do
      it "leaves the subscription in place" do
        delete "/my/push_subscriptions/#{subscription.id}"

        expect(PushSubscription.exists?(subscription.id)).to be(true)
      end
    end

    context "when signed in" do
      before { sign_in }

      it "removes the subscription and redirects to the push tab" do
        delete "/my/push_subscriptions/#{subscription.id}"

        expect(response).to redirect_to(my_notifications_path(tab: "push"))
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq(revoked_message)
        expect(PushSubscription.exists?(subscription.id)).to be(false)
      end

      it "answers a turbo stream request with the replaced component and a success flash" do
        delete "/my/push_subscriptions/#{subscription.id}", headers: turbo_headers

        expect(response).to have_http_status(:ok)
        assert_select "turbo-stream[action=replace][target=my-push-subscriptions]"
        assert_select "turbo-stream[action=flash] template", text: /#{Regexp.escape(revoked_message)}/
        expect(PushSubscription.exists?(subscription.id)).to be(false)
      end

      it "answers a silent turbo stream request without the flash" do
        delete "/my/push_subscriptions/#{subscription.id}", params: { silent: true }, headers: turbo_headers

        expect(response).to have_http_status(:ok)
        assert_select "turbo-stream[action=replace][target=my-push-subscriptions]"
        assert_select "turbo-stream[action=flash]", count: 0
        expect(PushSubscription.exists?(subscription.id)).to be(false)
      end

      it "does not find another user's subscription" do
        other = create(:push_subscription)

        delete "/my/push_subscriptions/#{other.id}"

        expect(response).to have_http_status(:not_found)
        expect(PushSubscription.exists?(other.id)).to be(true)
      end

      it "does not find an unknown subscription" do
        delete "/my/push_subscriptions/0"

        expect(response).to have_http_status(:not_found)
      end

      context "with the setting off", with_settings: { web_push_enabled: false } do
        it "is not found and keeps the subscription" do
          delete "/my/push_subscriptions/#{subscription.id}"

          expect(response).to have_http_status(:not_found)
          expect(PushSubscription.exists?(subscription.id)).to be(true)
        end
      end
    end
  end
end

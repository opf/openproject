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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
require "spec_helper"

RSpec.describe OpenIDConnect::UserTokens::RefreshService, :webmock do
  subject(:result) { service.call(token) }

  let(:service) { described_class.new(user:, token_exchange:) }
  let(:user) { create(:user, authentication_provider: provider) }
  let(:provider) { create(:oidc_provider) }

  let(:token_exchange) do
    instance_double(OpenIDConnect::UserTokens::ExchangeService, supported?: false)
  end

  let(:token) do
    user.oidc_user_tokens.create!(access_token: "a-token", refresh_token: "r-token", audiences: ["the-audience"])
  end

  let(:refresh_response) do
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: { access_token: "a-refreshed", refresh_token: "r-refreshed", expires_in: 20 }.to_json
    }
  end

  before do
    stub_request(:post, provider.token_endpoint)
      .with(body: hash_including(grant_type: "refresh_token"))
      .to_return(**refresh_response)
    token.save!
  end

  it { is_expected.to be_success }

  it "returns the updated token" do
    expect(result.value!).to eq(user.oidc_user_tokens.first)
  end

  it "updates the stored access token" do
    expect { subject }.to change { user.oidc_user_tokens.first.access_token }.from("a-token").to("a-refreshed")
  end

  it "updates the stored refresh token" do
    expect { subject }.to change { user.oidc_user_tokens.first.refresh_token }.from("r-token").to("r-refreshed")
  end

  it "updates the stored expiration time", :freeze_time do
    expect { subject }.to change { user.oidc_user_tokens.first.expires_at }.to(20.seconds.from_now.change(usec: 0))
  end

  context "when the refresh response has no expires_in" do
    let(:refresh_response) do
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
        body: { access_token: "a-refreshed", refresh_token: "r-refreshed" }.to_json
      }
    end

    it "updates the stored expiration time to nil" do
      subject
      expect(user.oidc_user_tokens.first.expires_at).to be_nil
    end
  end

  context "when the refresh response is unexpected JSON" do
    let(:refresh_response) do
      {
        status: 200, # misbehaving server responds with wrong JSON for success status
        headers: { "Content-Type": "application/json" },
        body: { error: "I can't let you do that Dave!" }.to_json
      }
    end

    it { is_expected.to be_failure }
  end

  context "when the refresh response has unexpected status" do
    let(:refresh_response) do
      {
        status: 502,
        headers: { "Content-Type": "text/html" },
        body: "<html><body>502 Bad Gateway</body></html>"
      }
    end

    it { is_expected.to be_failure }
  end

  context "when there is no refresh token" do
    let(:token) do
      user.oidc_user_tokens.create!(access_token: "a-token", refresh_token: nil, audiences: ["the-audience"])
    end

    it { is_expected.to be_failure }

    it "does not try to perform a token refresh" do
      subject
      expect(WebMock).not_to have_requested(:post, provider.token_endpoint)
        .with(body: hash_including(grant_type: "refresh_token"))
    end

    context "and the provider is token exchange capable" do
      let(:token_exchange) do
        instance_double(OpenIDConnect::UserTokens::ExchangeService, supported?: true, call: Success("exchange-result"))
      end

      it { is_expected.to be_success }

      it "returns the exchanged access token" do
        expect(result.value!).to eq("exchange-result")
      end

      it "tries to exchange for the token's audience" do
        subject
        expect(token_exchange).to have_received(:call).with("the-audience")
      end
    end
  end
end

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

RSpec.describe OpenIDConnect::UserTokens::ExchangeService, :webmock do
  let(:service) { described_class.new(user:) }
  let(:user) { create(:user, authentication_provider: provider) }
  let(:provider) { create(:oidc_provider, :token_exchange_capable) }

  let(:access_token) { "the-access-token" }
  let(:refresh_token) { "the-refresh-token" }
  let(:idp_access_token) { "the-idp-access-token" }

  let(:existing_audience) { "existing-audience" }

  let(:exchange_response) do
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: {
        access_token: "#{access_token}-exchanged",
        refresh_token: "#{refresh_token}-exchanged",
        expires_in: 45
      }.to_json
    }
  end
  let(:expected_expires_at) { 45.seconds.from_now.change(usec: 0) }

  before do
    user.oidc_user_tokens.create!(access_token: idp_access_token, audiences: [OpenIDConnect::UserToken::IDP_AUDIENCE])
    user.oidc_user_tokens.create!(access_token:, refresh_token:, audiences: [existing_audience])
    stub_request(:post, provider.token_endpoint)
      .with(body: hash_including(grant_type: OpenProject::OAuth2::TOKEN_EXCHANGE_GRANT_TYPE))
      .to_return(**exchange_response)
  end

  describe "#call" do
    subject(:result) { service.call(audience) }

    let(:audience) { "new-audience" }

    it { is_expected.to be_success }

    it "creates a new user token", :aggregate_failures, :freeze_time do
      expect { subject }.to change(user.oidc_user_tokens, :count).from(2).to(3)
      expect(user.oidc_user_tokens.last.access_token).to eq("the-access-token-exchanged")
      expect(user.oidc_user_tokens.last.refresh_token).to be_nil
      expect(user.oidc_user_tokens.last.expires_at).to eq(expected_expires_at)
    end

    it "returns the new user token" do
      expect(result.value!).to eq(user.oidc_user_tokens.last)
    end

    it "used the IDP access token to perform the exchange" do
      subject
      expect(WebMock).to have_requested(:post, provider.token_endpoint)
        .with(body: hash_including(subject_token: idp_access_token))
    end

    it "doesn't request any scopes" do
      subject
      expect(WebMock).to(have_requested(:post, provider.token_endpoint).with { |req| expect(req.body).not_to include("scope") })
    end

    context "when configuring a scope" do
      let(:service) { described_class.new(user:, scope:) }
      let(:scope) { "scope-a scope-b" }

      it "requests the scopes during token exchange" do
        subject
        expect(WebMock).to have_requested(:post, provider.token_endpoint)
          .with(body: hash_including(scope:))
      end
    end

    context "when the response has no expires_in" do
      let(:exchange_response) do
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
          body: {
            access_token: "#{access_token}-exchanged",
            refresh_token: "#{refresh_token}-exchanged"
          }.to_json
        }
      end

      it "creates a new user token without expiration", :aggregate_failures do
        expect { subject }.to change(user.oidc_user_tokens, :count).from(2).to(3)
        expect(user.oidc_user_tokens.last.expires_at).to be_nil
      end
    end

    context "when exchanging token for an existing user token" do
      let(:audience) { existing_audience }

      it { is_expected.to be_success }

      it "updates the existing user token", :aggregate_failures, :freeze_time do
        expect { subject }.not_to change(user.oidc_user_tokens, :count)
        expect(user.oidc_user_tokens.last.access_token).to eq("the-access-token-exchanged")
        expect(user.oidc_user_tokens.last.refresh_token).to be_nil
        expect(user.oidc_user_tokens.last.expires_at).to eq(expected_expires_at)
      end

      it "returns the updated user token" do
        expect(result.value!).to eq(user.oidc_user_tokens.last)
      end

      context "and when the response has no expires_in" do
        let(:exchange_response) do
          {
            status: 200,
            headers: { "Content-Type": "application/json" },
            body: {
              access_token: "#{access_token}-exchanged",
              refresh_token: "#{refresh_token}-exchanged"
            }.to_json
          }
        end

        it "updates the existing user token without expiration", :aggregate_failures do
          expect { subject }.not_to change(user.oidc_user_tokens, :count)
          expect(user.oidc_user_tokens.last.expires_at).to be_nil
        end
      end
    end

    context "when provider is not capable of token exchange" do
      let(:provider) { create(:oidc_provider) }

      it { is_expected.to be_failure }
    end
  end

  describe "#supported?" do
    subject { service.supported? }

    it { is_expected.to be_truthy }

    context "when provider is not capable of token exchange" do
      let(:provider) { create(:oidc_provider) }

      it { is_expected.to be_falsey }
    end
  end
end

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

RSpec.describe OpenIDConnect::UserTokens::FetchService, :webmock do
  let(:service) { described_class.new(user:, jwt_parser:, token_exchange:, token_refresh:) }
  let(:user) { create(:user) }
  let(:jwt_parser) { instance_double(OpenIDConnect::JwtParser, parse: Success([parsed_jwt, nil])) }
  let(:parsed_jwt) { { "exp" => Time.now.to_i + 60 } }

  let(:token_exchange) { instance_double(OpenIDConnect::UserTokens::ExchangeService, supported?: false) }
  let(:token_refresh) { instance_double(OpenIDConnect::UserTokens::RefreshService) }

  let(:access_token) { "the-access-token" }
  let(:refresh_token) { "the-refresh-token" }

  let(:existing_audience) { "existing-audience" }
  let(:queried_audience) { existing_audience }

  before do
    user.oidc_user_tokens.create!(access_token:, refresh_token:, audiences: [existing_audience])
    allow(token_refresh).to receive(:call) do |token|
      token.update!(access_token: "access-token-refreshed", refresh_token: "refresh-token-refreshed")
      Success(token)
    end
    allow(token_exchange).to receive(:call) do |aud|
      Success(user.oidc_user_tokens.create!(access_token: "access-token-exchanged",
                                            refresh_token: "refresh-token-exchanged",
                                            audiences: [aud]))
    end
    allow(OpenProject::Notifications).to receive(:send)
  end

  describe "#access_token_for" do
    subject(:result) { service.access_token_for(audience: queried_audience) }

    it { is_expected.to be_success }

    it "returns the stored access token" do
      expect(result.value!).to eq(access_token)
    end

    it "emits appropriate event" do
      result.value!

      expect(OpenProject::Notifications).to have_received(:send).with(
        described_class::TOKEN_OBTAINED_EVENT,
        token: instance_of(OpenIDConnect::UserToken),
        audience: queried_audience
      ).once
    end

    it "does not create RemoteIdentity if storage with appropriate audience is absent" do
      create(:nextcloud_storage, storage_audience: "not-expected-audience")
      expect { result }.not_to change(RemoteIdentity, :count)
    end

    context "when OpenProject notification raises an error" do
      let(:error) { StandardError.new("I am an error") }

      before do
        allow(OpenProject::Notifications).to receive(:send).and_raise(error)
      end

      it "raises the same error" do
        expect { result }.to raise_error(error)
      end
    end

    context "when the token doesn't expire and can't be parsed as JWT" do
      let(:jwt_parser) { instance_double(OpenIDConnect::JwtParser, parse: Failure("Not a valid JWT")) }

      it { is_expected.to be_success }

      it "returns the stored access token" do
        expect(result.value!).to eq(access_token)
      end
    end

    context "when it is expired" do
      before do
        user.oidc_user_tokens.first.update!(expires_at: Time.zone.now)
      end

      it { is_expected.to be_success }

      it "returns the refreshed access token" do
        expect(result.value!).to eq("access-token-refreshed")
      end
    end

    context "when it expires in the future" do
      before do
        user.oidc_user_tokens.first.update!(expires_at: 10.seconds.from_now)
      end

      it { is_expected.to be_success }

      it "returns the stored access token" do
        expect(result.value!).to eq(access_token)
      end
    end

    context "when parsing the token reveals, that it is expired" do
      let(:parsed_jwt) { { "exp" => Time.now.to_i } }

      it { is_expected.to be_success }

      it "returns the refreshed access token" do
        expect(result.value!).to eq("access-token-refreshed")
      end
    end

    context "when audience can't be found" do
      let(:queried_audience) { "wrong-audience" }

      it { is_expected.to be_failure }

      it "does not attempt a token exchange" do
        subject
        expect(token_exchange).not_to have_received(:call)
      end

      context "and the provider is token exchange capable" do
        let(:token_exchange) { instance_double(OpenIDConnect::UserTokens::ExchangeService, supported?: true) }

        it { is_expected.to be_success }

        it "returns the exchanged access token" do
          expect(result.value!).to eq("access-token-exchanged")
        end

        it "tries to exchange the correct audience" do
          subject
          expect(token_exchange).to have_received(:call).with(queried_audience)
        end
      end
    end
  end

  describe "instantiation" do
    let(:service) { described_class.new(user:) }
    let(:user) { create(:user) }

    let(:jwt_parser) { instance_double(OpenIDConnect::JwtParser) }
    let(:exchange_service) { instance_double(OpenIDConnect::UserTokens::ExchangeService) }
    let(:refresh_service) { instance_double(OpenIDConnect::UserTokens::RefreshService) }

    before do
      allow(OpenIDConnect::JwtParser).to receive(:new).and_return(jwt_parser)
      allow(OpenIDConnect::UserTokens::ExchangeService).to receive(:new).and_return(exchange_service)
      allow(OpenIDConnect::UserTokens::RefreshService).to receive(:new).and_return(refresh_service)
    end

    it "uses a non-verifying JWT parser" do
      service
      expect(OpenIDConnect::JwtParser).to have_received(:new).with(verify_audience: false, verify_expiration: false)
    end

    it "configures an exchange service" do
      service
      expect(OpenIDConnect::UserTokens::ExchangeService).to have_received(:new).with(user:, scope: nil)
    end

    it "configures a refresh service" do
      service
      expect(OpenIDConnect::UserTokens::RefreshService).to have_received(:new).with(user:, token_exchange: exchange_service)
    end

    context "when specifying exchange_scope" do
      let(:service) { described_class.new(user:, exchange_scope: "scope-a scope-b") }

      it "configures the exchange service with the correct scope" do
        service
        expect(OpenIDConnect::UserTokens::ExchangeService).to have_received(:new).with(user:, scope: "scope-a scope-b")
      end

      it "configures a refresh service" do
        service
        expect(OpenIDConnect::UserTokens::RefreshService).to have_received(:new).with(user:, token_exchange: exchange_service)
      end
    end
  end
end

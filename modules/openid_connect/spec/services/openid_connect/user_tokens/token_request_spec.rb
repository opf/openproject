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

RSpec.describe OpenIDConnect::UserTokens::TokenRequest, :webmock do
  let(:service) { described_class.new(provider:) }
  let(:provider) { create(:oidc_provider, client_id:, client_secret:) }
  let(:client_id) { "openproject" }
  let(:client_secret) { "a-secret" }

  let(:response) do
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: { access_token: "an-access-token" }.to_json
    }
  end

  before do
    stub_request(:post, provider.token_endpoint).to_return(**response)
  end

  describe "#refresh" do
    subject { service.refresh(token) }

    let(:token) { "a-refresh-token" }

    it { is_expected.to be_success }

    it "returns the decoded JSON response" do
      expect(subject.value!).to eq({ "access_token" => "an-access-token" })
    end

    it "uses a properly formatted request body" do
      subject
      expect(WebMock).to have_requested(:post, provider.token_endpoint)
        .with(body: { grant_type: "refresh_token", refresh_token: token })
    end

    it "authenticates the request via HTTP Basic auth using Client ID and Client Secret" do
      subject
      expect(WebMock).to(have_requested(:post, provider.token_endpoint).with do |request|
        auth_header = request.headers["Authorization"]
        type, credentials = auth_header.split
        expect(type).to eq "Basic"
        expect(Base64.decode64(credentials)).to eq "#{client_id}:#{client_secret}"
      end)
    end

    context "when the Client ID and Client Secret contain special characters" do
      let(:client_id) { "https://openproject.local" }
      let(:client_secret) { "a-secret/with:special-characters" }

      it "escapes Basic Auth credentials" do
        subject
        expect(WebMock).to(have_requested(:post, provider.token_endpoint).with do |request|
          auth_header = request.headers["Authorization"]
          _, credentials = auth_header.split
          expect(Base64.decode64(credentials)).to eq "https%3A%2F%2Fopenproject.local:a-secret%2Fwith%3Aspecial-characters"
        end)
      end
    end

    context "when the request fails" do
      let(:response) do
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
          body: { error: "invalid_client" }.to_json
        }
      end

      it { is_expected.not_to be_success }

      it "returns the error response" do
        expect(subject.failure).to be_a(OpenIDConnect::TokenOperationError)
        expect(subject.failure.code).to eq(:unauthorized)
      end
    end
  end

  describe "#exchange" do
    subject { service.exchange(token, audience, scope) }

    let(:token) { "a-refresh-token" }
    let(:audience) { "target-audience" }
    let(:scope) { nil }

    it { is_expected.to be_success }

    it "returns the decoded JSON response" do
      expect(subject.value!).to eq({ "access_token" => "an-access-token" })
    end

    it "uses a properly formatted request body" do
      subject
      expect(WebMock).to have_requested(:post, provider.token_endpoint)
        .with(body: {
                grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
                subject_token: token,
                subject_token_type: "urn:ietf:params:oauth:token-type:access_token",
                audience:
              })
    end

    it "authenticates the request via HTTP Basic auth using Client ID and Client Secret" do
      subject
      expect(WebMock).to(have_requested(:post, provider.token_endpoint).with do |request|
        auth_header = request.headers["Authorization"]
        type, credentials = auth_header.split
        expect(type).to eq "Basic"
        expect(Base64.decode64(credentials)).to eq "#{client_id}:#{client_secret}"
      end)
    end

    context "when the Client ID and Client Secret contain special characters" do
      let(:client_id) { "https://openproject.local" }
      let(:client_secret) { "a-secret/with:special-characters" }

      it "escapes Basic Auth credentials" do
        subject
        expect(WebMock).to(have_requested(:post, provider.token_endpoint).with do |request|
          auth_header = request.headers["Authorization"]
          _, credentials = auth_header.split
          expect(Base64.decode64(credentials)).to eq "https%3A%2F%2Fopenproject.local:a-secret%2Fwith%3Aspecial-characters"
        end)
      end
    end

    context "when passing a scope" do
      let(:scope) { "scope-a scope-b" }

      it "includes the scope in the request body" do
        subject
        expect(WebMock).to have_requested(:post, provider.token_endpoint)
          .with(body: {
                  grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
                  subject_token: token,
                  subject_token_type: "urn:ietf:params:oauth:token-type:access_token",
                  audience:,
                  scope:
                })
      end
    end

    context "when the request fails" do
      let(:response) do
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
          body: { error: "invalid_client" }.to_json
        }
      end

      it { is_expected.not_to be_success }

      it "returns the error response" do
        expect(subject.failure).to be_a(OpenIDConnect::TokenOperationError)
        expect(subject.failure.code).to eq(:unauthorized)
      end
    end
  end
end

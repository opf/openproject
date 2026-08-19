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
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Validators
          RSpec.describe AuthenticationValidator, :disable_ssrf_filter, :webmock do
            subject(:validator) { described_class.new(storage) }

            context "when using OAuth2" do
              let(:user) { create(:user) }
              let(:storage) do
                create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed,
                       oauth_client_token_user: user, origin_user_id: "m.jade@death.star")
              end

              before { User.current = user }

              it "passes when the user has a token and the request works", vcr: "nextcloud/user_query_success" do
                expect(validator.call).to be_success
              end

              it "returns a warning when there's no token for the current user" do
                User.current = create(:user)
                result = validator.call

                expect(result[:existing_token]).to be_a_warning
                expect(result[:existing_token].code).to eq(:nc_oauth_token_missing)
                expect(result[:user_bound_request]).to be_skipped
              end

              it "returns a failure if the remote call failed" do
                error = Results::Error.new(code: :unauthorized, source: self)
                Registry.stub("nextcloud.queries.user", ->(_) { Failure(error) })

                result = validator.call
                expect(result[:user_bound_request]).to be_a_failure
                expect(result[:user_bound_request].code).to eq(:nc_oauth_request_unauthorized)
              end
            end

            context "when using OpenID Connect" do
              let(:storage) { create(:nextcloud_storage_configured, :oidc_sso_enabled, storage_audience:) }
              let(:storage_audience) { OpenIDConnect::UserToken::IDP_AUDIENCE }

              let(:user) { create(:user, identity_url: "#{oidc_provider.slug}:123123123123") }
              let!(:oidc_provider) { create(:oidc_provider, scope:) }
              let!(:saml_provider) { create(:saml_provider) }
              let(:scope) { "openid email profile offline_access" }

              before do
                User.current = user

                xml_response = Rails.root.join("modules/storages/spec/support/payloads/nextcloud_user_query_success.xml")
                stub_request(:get, "#{storage.uri}ocs/v1.php/cloud/user")
                  .and_return(status: 200, body: File.read(xml_response), headers: { content_type: "text/xml" })
              end

              it "succeeds give the user is provisioned and tokens can be acquired" do
                create(:oidc_user_token, user:, extra_audiences: storage.audience)
                expect(validator.call).to be_success
              end

              describe "error and warning handling" do
                it "returns a warning if the current user isn't provisioned" do
                  user.user_auth_provider_links.destroy_all
                  result = validator.call

                  expect(result[:non_provisioned_user]).to be_warning
                  expect(result[:non_provisioned_user].code).to eq(:oidc_non_provisioned_user)

                  state_count = result.tally
                  expect(state_count).to eq({ skipped: 5, warning: 1 })
                end

                it "returns a warning if the user is not provisioned by an oidc provider" do
                  link = user.user_auth_provider_links.first
                  link.update!(auth_provider_id: saml_provider.id)

                  result = validator.call

                  expect(result[:provisioned_user_provider]).to be_warning
                  expect(result[:provisioned_user_provider].code).to eq(:oidc_non_oidc_user)

                  state_count = result.tally
                  expect(state_count).to eq({ success: 1, skipped: 4, warning: 1 })
                end

                context "when the offline_access scope is not configured" do
                  let(:scope) { "openid email profile" }

                  it "returns a warning", :aggregate_failures do
                    create(:oidc_user_token, user:, extra_audiences: storage.audience)
                    result = validator.call

                    expect(result[:offline_access]).to be_warning
                    expect(result[:offline_access].code).to eq(:offline_access_scope_missing)

                    state_count = result.tally
                    expect(state_count).to eq({ success: 5, warning: 1 })
                  end
                end

                context "when configured to exchange a token" do
                  let(:storage_audience) { "my-audience" }

                  it "returns an error"  do
                    create(:oidc_user_token, user:, extra_audiences: storage.audience)
                    result = validator.call

                    expect(result[:provider_capabilities]).to be_failure
                    expect(result[:provider_capabilities].code).to eq(:oidc_provider_cant_exchange)

                    state_count = result.tally
                    expect(state_count).to eq({ success: 2, failure: 1, skipped: 3 })
                  end

                  context "and when the OIDC provider can exchange tokens" do
                    let!(:oidc_provider) { create(:oidc_provider, :token_exchange_capable, scope:) }

                    it "succeeds" do
                      create(:oidc_user_token, user:, extra_audiences: storage.audience)
                      expect(validator.call).to be_success
                    end
                  end
                end
              end

              describe "checks related to the token" do
                context "when the existing token requires a refresh" do
                  let(:expired_storage_token) do
                    create(:oidc_user_token, user:, extra_audiences: storage.audience, expires_at: 10.hours.ago)
                  end

                  it "tries to refresh the token if it is expired" do
                    refresh_request = stub_request(:post, oidc_provider.token_endpoint)
                                        .with(body: { grant_type: "refresh_token",
                                                      refresh_token: expired_storage_token.refresh_token })
                                        .and_return_json(status: 200, body: { access_token: "NEW_TOKEN" })

                    expect(validator.call).to be_success
                    expect(refresh_request).to have_been_requested.once
                  end

                  it "fails when the refresh response is invalid" do
                    stub_request(:post, oidc_provider.token_endpoint)
                      .with(body: { grant_type: "refresh_token", refresh_token: expired_storage_token.refresh_token })
                      .and_return_json(status: 200, body: { error: "this is a broken endpoint" })

                    result = validator.call

                    expect(result[:token_negotiable]).to be_failure
                    expect(result[:token_negotiable].code).to eq(:oidc_token_refresh_failed)
                  end

                  it "fails when refresh fails" do
                    stub_request(:post, oidc_provider.token_endpoint)
                      .with(body: { grant_type: "refresh_token", refresh_token: expired_storage_token.refresh_token })
                      .and_return(status: 401)

                    result = validator.call

                    expect(result[:token_negotiable]).to be_failure
                    expect(result[:token_negotiable].code).to eq(:oidc_token_refresh_failed)
                  end

                  context "when the server supports token exchange" do
                    let(:storage_audience) { "my-audience" }

                    let(:oidc_provider) { create(:oidc_provider, :token_exchange_capable, scope: "offline_access") }
                    let!(:exchangeable_token) { create(:oidc_user_token, user:, refresh_token: nil) }

                    it "favors token exchange when refreshing" do
                      exchange_request = stub_request(:post, oidc_provider.token_endpoint)
                                           .with(body: hash_including(
                                             grant_type: OpenProject::OpenIDConnect::TOKEN_EXCHANGE_GRANT_TYPE
                                           ))
                                           .and_return_json(status: 200, body: { access_token: "NEW_TOKEN" })

                      expect(validator.call).to be_success
                      expect(exchange_request).to have_been_requested.once
                    end

                    it "fails if the exchange is met with an unexpected body" do
                      exchange_request = stub_request(:post, oidc_provider.token_endpoint)
                                           .with(body: hash_including(
                                             grant_type: OpenProject::OpenIDConnect::TOKEN_EXCHANGE_GRANT_TYPE
                                           ))
                                           .and_return_json(status: 200, body: { error: "failed " })

                      result = validator.call

                      expect(result[:token_negotiable]).to be_failure
                      expect(result[:token_negotiable].code).to eq(:oidc_token_exchange_failed)
                      expect(exchange_request).to have_been_requested.once
                    end

                    it "fails if the exchange fails" do
                      exchange_request = stub_request(:post, oidc_provider.token_endpoint)
                                           .with(body: hash_including(
                                             grant_type: OpenProject::OpenIDConnect::TOKEN_EXCHANGE_GRANT_TYPE
                                           ))
                                           .and_return(status: 401)

                      result = validator.call

                      expect(result[:token_negotiable]).to be_failure
                      expect(result[:token_negotiable].code).to eq(:oidc_token_exchange_failed)
                      expect(exchange_request).to have_been_requested.once
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

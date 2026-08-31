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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OAuthClients::TokenFetcher, :webmock do
  subject(:fetch_token) { described_class.new(user:).access_token_for(oauth_client:) }

  let(:user) { create(:user) }
  let(:oauth_client) { create(:oauth_client) }
  let(:existing_token) { create(:oauth_client_token, user:, oauth_client:, expires_in: ttl, updated_at: expires_since) }

  let(:ttl) { 3600 }
  let(:expires_since) { 10.minutes.ago }

  let(:token_request) { instance_double(OAuthClients::TokenRequest, refresh: refresh_response) }
  let(:refresh_response) do
    Success({ "access_token" => new_access_token, "refresh_token" => new_refresh_token, "expires_in" => new_ttl })
  end
  let(:new_access_token) { "the-new-access-token" }
  let(:new_refresh_token) { "the-new-refresh-token" }
  let(:new_ttl) { 7200 }

  before do
    existing_token.save!

    allow(OAuthClients::TokenRequest).to receive(:new).and_return(token_request)
  end

  context "when the token has not yet expired" do
    it "does not refresh the token" do
      fetch_token
      expect(token_request).not_to have_received(:refresh)
    end

    it "returns the access token" do
      expect(fetch_token).to be_success
      expect(fetch_token.value!).to eq(existing_token.access_token)
    end
  end

  context "when the token never expires" do
    let(:ttl) { nil }

    it "does not refresh the token" do
      fetch_token
      expect(token_request).not_to have_received(:refresh)
    end

    it "returns the access token" do
      expect(fetch_token).to be_success
      expect(fetch_token.value!).to eq(existing_token.access_token)
    end
  end

  context "when the token has expired" do
    let(:expires_since) { (ttl + 60).seconds.ago }

    it "refreshes the token" do
      fetch_token

      existing_token.reload
      expect(existing_token).to have_attributes(access_token: new_access_token,
                                                refresh_token: new_refresh_token,
                                                expires_in: new_ttl)
      expect(existing_token.updated_at).to be_within(5.seconds).of(Time.zone.now)
    end

    it "returns the refreshed access token" do
      expect(fetch_token).to be_success
      expect(fetch_token.value!).to eq(new_access_token)
    end

    it "instantiates token_request with proper parameters" do
      fetch_token

      expect(OAuthClients::TokenRequest).to have_received(:new).with(
        client_id: oauth_client.client_id,
        client_secret: oauth_client.client_secret,
        # TODO: this is a pretty long call chain; ideally it would be accessible more directly and it would be SET through
        # this spec, not merely read
        token_endpoint: oauth_client.integration.oauth_configuration.token_endpoint
      )
    end

    context "and when the token is concurrently being refreshed in the background" do
      subject(:fetch_token) do
        concurrency_semaphore.release
        described_class.new(user:).access_token_for(oauth_client:)
      end

      # Semaphore used to ensure that the background thread performs the first request
      let(:startup_semaphore) { Concurrent::Semaphore.new(0) }

      # Semaphore used to slow down response of background thread enough to ensure that the foreground
      # thread had to wait for the background thread
      let(:concurrency_semaphore) { Concurrent::Semaphore.new(0) }

      let(:token_request) do
        instance_double(OAuthClients::TokenRequest).tap do |request|
          # RSpec seems to have multi-threading limits, calculating refresh_response while the main thread is locked up does
          # not seem to work. Thus we assign it outside of the mocked response block below
          response = refresh_response
          main_thread = Thread.current
          first_request = true
          allow(request).to receive(:refresh) do
            unless first_request
              next Success(
                { "access_token" => "wrong-access-token", "refresh_token" => "wrong-refresh-token", "expires_in" => new_ttl }
              )
            end
            first_request = false
            startup_semaphore.release
            concurrency_semaphore.acquire
            # our test locking is imperfect: we want to continue here, once the foreground thread ran into the SQL lock
            # we are testing. So we give the foreground thread additional time to acquire the lock-under-test
            loop do
              sleep(0.5)
              break if main_thread.status == "sleep"
            end

            response
          end
        end
      end

      before do
        Thread.new do
          described_class.new(user:).access_token_for(oauth_client:)
        end

        startup_semaphore.acquire
      end

      it "refreshes the token only once (in the background)" do
        fetch_token
        expect(token_request).to have_received(:refresh).once
      end

      it "returns the previously refreshed token on the foreground request" do
        expect(fetch_token).to be_success
        expect(fetch_token.value!).to eq(new_access_token)
      end
    end

    context "and when the refresh endpoint responds with an error" do
      let(:token_request) { instance_double(OAuthClients::TokenRequest, refresh: Failure(:carl)) }

      it "returns the error" do
        expect(fetch_token).to be_failure
        expect(fetch_token.failure).to eq(:carl)
      end

      it "does not change the token" do
        expect { fetch_token }.not_to change { existing_token.reload.attributes }
      end
    end

    context "and when the refresh endpoint does not return an access token" do
      let(:refresh_response) do
        Success({ "error" => "This response wasn't as successful as it seemed." })
      end

      it "returns an error" do
        expect(fetch_token).to be_failure
        expect(fetch_token.failure).to have_attributes(code: :token_refresh_response_invalid)
      end

      it "does not change the token" do
        expect { fetch_token }.not_to change { existing_token.reload.attributes }
      end
    end
  end

  context "when the token is about to expire in less than 10 seconds" do
    let(:expires_since) { (ttl - 5).seconds.ago }

    it "refreshes the token" do
      fetch_token

      existing_token.reload
      expect(existing_token).to have_attributes(access_token: new_access_token,
                                                refresh_token: new_refresh_token,
                                                expires_in: new_ttl)
      expect(existing_token.updated_at).to be_within(5.seconds).of(Time.zone.now)
    end

    it "returns the refreshed access token" do
      expect(fetch_token).to be_success
      expect(fetch_token.value!).to eq(new_access_token)
    end
  end

  context "when there is no token for the given user and app" do
    let(:existing_token) { create(:oauth_client_token, oauth_client:) }

    it "returns a failure" do
      expect(fetch_token).to be_failure
      expect(fetch_token.failure).to have_attributes(code: :missing_token)
    end
  end
end

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

RSpec.describe My::AccessTokensController do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "rss" do
    it "creates a key" do
      expect(user.rss_token).to be_nil

      post :generate_rss_key, format: :turbo_stream
      expect(user.reload.rss_token).to be_present

      expect(flash[:error]).to be_blank

      expect(response).to be_successful
      expect(response.body).to include(user.rss_token.value)
    end

    context "with existing key" do
      let!(:key) { Token::RSS.create user: }

      it "replaces the key" do
        expect(user.rss_token).to eq(key)

        post :generate_rss_key, format: :turbo_stream
        new_token = user.reload.rss_token
        expect(new_token).not_to eq(key)
        expect(new_token.value).not_to eq(key.value)
        expect(new_token.value).to eq(user.rss_key)

        expect(flash[:error]).not_to be_present
        expect(response).to be_successful
        expect(response.body).to include(new_token.value)
      end
    end
  end

  describe "api" do
    context "with no existing key" do
      it "creates a key" do
        expect(user.api_tokens).to be_empty

        post :generate_api_key, params: { token_api: { token_name: "One heck of a token" } }, format: :turbo_stream
        new_token = user.reload.api_tokens.last
        expect(new_token).to be_present

        expect(response).to be_successful
        expect(response.body).to include(new_token.token_name)
      end
    end

    context "with existing key" do
      let!(:key) { Token::API.create(user:, data: { name: "One heck of a token" }) }

      it "must add the new key" do
        expect(user.reload.api_tokens.last).to eq(key)

        post :generate_api_key, params: { token_api: { token_name: "Two heck of a token" } }, format: :turbo_stream

        new_token = user.reload.api_tokens.last
        expect(new_token).not_to eq(key)
        expect(new_token.value).not_to eq(key.value)

        expect(response).to be_successful
        expect(response.body).to include("Two heck of a token")
      end
    end

    describe "expiry" do
      let(:user) { create(:user, preferences: { time_zone: "Europe/Berlin" }) }
      let(:berlin) { Time.find_zone("Europe/Berlin") }
      let(:in_a_week) { berlin.today + 7.days }

      def generate(expiry_params)
        post :generate_api_key,
             params: { token_api: { token_name: "Expiring token", **expiry_params } },
             format: :turbo_stream
      end

      it "expires on the selected preset day" do
        generate(expiry: in_a_week.iso8601)

        expect(user.api_tokens.last.expires_on_date).to eq(in_a_week)
      end

      it "expires on the custom date" do
        generate(expiry: "custom", expires_on_date: in_a_week.iso8601)

        expect(user.api_tokens.last.expires_on_date).to eq(in_a_week)
      end

      it "never expires when no expiration is selected" do
        generate(expiry: "never", expires_on_date: in_a_week.iso8601)

        expect(user.api_tokens.last.expires_on).to be_nil
      end

      it "re-renders the form with an error for a past custom date" do
        generate(expiry: "custom", expires_on_date: (berlin.today - 1.day).iso8601)

        expect(response).to have_http_status(:bad_request)
        expect(user.api_tokens).to be_empty
        expect(response.body).to include("Expiration date must be in the future.")
      end
    end
  end

  describe "ical" do
    # unlike with the other tokens, creating new ical tokens is not done in this context
    # ical tokens are generated whenever the user requests a new ical url
    # a user can have N ical tokens
    #
    # in this context a specific ical token of a user should be reverted
    # this invalidates the previously generated ical url
    context "with existing keys" do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:query) { create(:query, project:) }
      let(:another_query) { create(:query, project:) }
      let!(:ical_token_for_query) { create(:ical_token, user:, query:, name: "Some Token Name") }
      let!(:another_ical_token_for_query) { create(:ical_token, user:, query:, name: "Some Other Token Name") }
      let!(:ical_token_for_another_query) { create(:ical_token, user:, query: another_query, name: "Some Token Name") }

      it "revoke specific ical tokens" do
        expect(user.ical_tokens).to contain_exactly(
          ical_token_for_query, another_ical_token_for_query, ical_token_for_another_query
        )

        delete :revoke_ical_token, params: { access_token_id: another_ical_token_for_query.id }

        expect(user.ical_tokens.reload).to contain_exactly(
          ical_token_for_query, ical_token_for_another_query
        )

        expect(user.ical_tokens.reload).not_to contain_exactly(
          ical_token_for_another_query
        )

        expect(flash[:info]).to be_present
        expect(flash[:error]).not_to be_present

        expect(response).to redirect_to action: :index
      end
    end
  end

  describe "oauth client tokens" do
    let(:client) { create(:oauth_client, integration: create(:nextcloud_storage)) }
    let(:token) { create(:oauth_client_token, oauth_client: client, scope: nil, user:, expires_in: 3_600) }

    render_views

    before { token }

    it "lists the tokens" do
      get :index, params: { tab: :client }

      expect(response).to be_successful
      expect(response.body).to have_css("[data-test-selector=oauth-client-token-#{token.id}]")
    end

    it "can remove the token" do
      expect do
        delete :remove_oauth_client_token, params: { access_token_id: token.id }
      end.to change(OAuthClientToken, :count).by(-1)

      expect(flash[:info]).to be_present
      expect(flash[:error]).not_to be_present
      expect(response).to redirect_to(action: :index, tab: :client)
    end
  end
end

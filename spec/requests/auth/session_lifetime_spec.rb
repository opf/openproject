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

RSpec.describe "Browser session expiration", :skip_2fa_stage, :skip_csrf,
               type: :rails_request,
               with_settings: { session_ttl_enabled?: true, session_ttl: "30" } do
  let(:password) { "Password123!" }
  let(:user) { create(:user, password:, password_confirmation: password, force_password_change: false) }
  let(:ttl) { Setting.session_ttl.to_i.minutes }
  let(:cookie_name) { OpenProject::Configuration["session_cookie_name"] }
  let(:cookie_value) { cookies[cookie_name] }
  let(:browser_session) { Sessions::UserSession.find_by!(session_id: session.id.private_id, user_id: user.id) }
  let(:app) { Rails.application.middleware.build(test_routes) }

  let(:test_routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        get "/session_test", to: "session_lifetime_test#show"
        mount Rails.application.routes => "/"
      end
    end
  end

  before do
    stub_const("SessionLifetimeTestController", Class.new(ApplicationController) do
      authorization_checked! :show
      before_action :require_login

      def show
        render plain: "OK"
      end

      private

      def login_back_url
        request.original_url
      end
    end)

    post "/login", params: { username: user.login, password: }
    cookie_value
    browser_session
  end

  shared_examples "an expired browser session" do
    it "clears the expired session" do
      travel ttl + 1.minute do
        get request_path, headers: request_headers

        expect(response).to redirect_to(%r{/login\?})
        expect(Sessions::UserSession.exists?(browser_session.id)).to be false

        cookies[cookie_name] = cookie_value
        get "/session_test"

        expect(response).to redirect_to(%r{/login\?})
        expect(session[:user_id]).to be_nil
      end
    end
  end

  context "on an HTML route" do
    let(:request_path) { "/session_test" }
    let(:request_headers) { {} }

    it_behaves_like "an expired browser session"
  end

  %i[json xml].each do |format|
    context "with #{format} responses" do
      let(:request_path) { "/session_test.#{format}" }
      let(:request_headers) { {} }

      it_behaves_like "an expired browser session"
    end

    context "with #{format} content negotiation" do
      let(:request_path) { "/session_test" }
      let(:request_headers) { { "Accept" => Mime[format].to_s } }

      it_behaves_like "an expired browser session"
    end
  end

  it "refreshes an active session" do
    travel ttl / 2 do
      get "/session_test.json"

      expect(response).to have_http_status(:ok)
      expect(browser_session.reload.data["updated_at"]).to be_within(1.second).of(Time.current)

      get "/session_test"

      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  it "rejects an expired API v3 session without refreshing its activity" do
    last_seen = browser_session.data["updated_at"]
    row_updated_at = browser_session.updated_at

    travel ttl + 1.minute do
      get "/api/v3/users/me", headers: { "Accept" => "application/hal+json" }

      expect(response).to have_http_status(:unauthorized)
      expect(browser_session.reload.data["updated_at"]).to eq(last_seen)
      expect(browser_session.updated_at).to eq(row_updated_at)
    end
  end

  it "rejects a cookie whose session row has been deleted" do
    Sessions::UserSession.where(id: browser_session.id).delete_all

    get "/session_test.json"

    expect(response).to have_http_status(:unauthorized)
    expect(Sessions::UserSession.exists?(browser_session.id)).to be false
  end

  it "rejects a session belonging to an inactive user" do
    user.locked!

    get "/session_test.json"

    expect(response).to have_http_status(:unauthorized)
  end
end

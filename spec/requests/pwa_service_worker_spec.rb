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

RSpec.describe "PWA service worker", type: :rails_request, with_flag: { progressive_web_app: true } do
  include CspHelper

  shared_context "with a relative url root" do
    around do |example|
      previous = OpenProject::Configuration["rails_relative_url_root"]
      OpenProject::Configuration["rails_relative_url_root"] = "/openproject"
      example.run
    ensure
      OpenProject::Configuration["rails_relative_url_root"] = previous
    end
  end

  let(:controller_selector) { 'body[data-controller~="pwa-service-worker"]' }

  it "does not route a format suffix" do
    expect { get "/service-worker.js" }.to raise_error(ActionController::RoutingError)
  end

  describe "GET /service-worker", with_settings: { login_required: true } do
    before { get "/service-worker" }

    it "is served as JavaScript to a visitor without a session" do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end

    it "carries the page-level content security policy" do
      csp = parse_csp(response.headers["Content-Security-Policy"])

      expect(csp["script-src"]).to include(a_string_starting_with("'nonce-"))
    end

    it "must be revalidated so browsers pick up a new worker" do
      expect(response.headers["Cache-Control"]).to include("no-cache")
    end

    it "sets no session cookie for a visitor without a session" do
      expect(response.headers["Set-Cookie"]).to be_blank
    end

    it "takes control of its clients" do
      expect(response.body).to include("skipWaiting", "clients.claim")
    end

    it "precaches the offline page under the configured cache name" do
      expect(response.body).to include(ApplicationController.helpers.pwa_cache_name, '"/offline"')
    end

    context "when served under a path prefix" do
      include_context "with a relative url root"

      it "points at the prefixed offline page" do
        get "/service-worker", env: { "SCRIPT_NAME" => "/openproject" }

        expect(response.body).to include('"/openproject/offline"')
      end
    end
  end

  describe "GET /service-worker with an expired browser session",
           :skip_csrf,
           with_settings: { session_ttl_enabled?: true, session_ttl: "120" } do
    let(:user) { create(:admin) }

    it "is still served as JavaScript" do
      post "/login", params: { username: user.login, password: "adminADMIN!" }
      follow_redirect! while response.redirect?

      travel 3.hours
      get "/service-worker"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end
  end

  describe "the registration wiring" do
    before { login_as create(:user) }

    it "registers the worker on the page" do
      get "/my/page"

      expect(page).to have_css(controller_selector, visible: :all)
    end

    context "when served under a path prefix" do
      include_context "with a relative url root"

      it "registers the prefixed worker and scope" do
        get "/my/page", env: { "SCRIPT_NAME" => "/openproject" }

        expect(page).to have_css('body[data-pwa-service-worker-url-value="/openproject/service-worker"]', visible: :all)
        expect(page).to have_css('body[data-pwa-service-worker-scope-value="/openproject/"]', visible: :all)
      end
    end
  end

  it "registers the worker on the logo-only layout too" do
    get "/404"

    expect(page).to have_css(controller_selector, visible: :all)
  end

  context "with the feature flag off", with_flag: { progressive_web_app: false } do
    it "serves a worker that removes the offline caches and unregisters itself" do
      get "/service-worker"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include("openproject-offline-", "unregister")
      expect(response.body).not_to include('addEventListener("fetch"')
    end

    it "registers no worker" do
      get "/login"

      expect(page).to have_no_css(controller_selector, visible: :all)
    end
  end
end

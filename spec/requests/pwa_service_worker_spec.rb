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

RSpec.describe "PWA service worker", type: :rails_request, with_flag: { progressive_web_app: true } do
  include CspHelper

  def worker_config
    JSON.parse(response.body[/self\.OP_SW = (.+);$/, 1])
  end

  let(:controller_selector) { 'body[data-controller~="pwa-service-worker"]' }

  it "does not route a format suffix" do
    expect { get "/service-worker.js" }.to raise_error(ActionController::RoutingError)
  end

  it "imports the hashed bundle when the manifest has one" do
    allow(FrontendAssetHelper).to receive(:assets_proxied?).and_return(false)
    allow(OpenProject::Assets).to receive(:lookup_asset).and_call_original
    allow(OpenProject::Assets).to receive(:lookup_asset).with("service-worker.js").and_return("service-worker-abc123.js")

    get "/service-worker"

    expect(response.body).to include('importScripts("/assets/frontend/service-worker-abc123.js")')
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

    it "imports the worker logic from the frontend bundle" do
      expect(response.body).to match(%r{importScripts\("[^"]*/assets/frontend/service-worker[^"]*\.js"\)})
    end

    it "hands the bundle its configuration" do
      config = worker_config

      expect(config.dig("urls", "offline")).to eq("/offline")
      expect(config.dig("urls", "push")).to eq("/api/v3/notifications/summary")
      expect(config.dig("urls", "signOut")).to eq("/logout")
      expect(config.dig("urls", "home")).to eq("/")
      expect(config["cache"]).to include("name" => ApplicationController.helpers.pwa_cache_name,
                                         "prefix" => ApplicationController.helpers.pwa_cache_prefix,
                                         "state" => "#{ApplicationController.helpers.pwa_cache_prefix}push-state")
      expect(config.dig("push", "icon")).to match(%r{/assets/pwa/icon-192.*\.png\z})
      expect(config.dig("push", "fallbackTitle")).to eq("New activity in OpenProject")
      expect(config.dig("push", "allReadTitle")).to eq("No unread notifications")
    end

    context "when served under a path prefix", with_config: { rails_relative_url_root: "/openproject" } do
      it "prefixes the configured paths and the bundle" do
        allow(Rails.application.config).to receive(:relative_url_root).and_return("/openproject")

        get "/service-worker", env: { "SCRIPT_NAME" => "/openproject" }

        expect(worker_config["urls"]).to include("offline" => "/openproject/offline",
                                                 "push" => "/openproject/api/v3/notifications/summary")
        expect(response.body).to match(%r{importScripts\("[^"]*/openproject/assets/frontend/service-worker})
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

    context "when served under a path prefix", with_config: { rails_relative_url_root: "/openproject" } do
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
    it "serves a worker that removes the offline caches and unregisters itself, without the bundle" do
      get "/service-worker"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include("openproject-offline-", "unregister")
      expect(response.body).to include(%(const CACHE_PREFIX = "#{ApplicationController.helpers.pwa_cache_prefix}";))
      expect(response.body.scan("const CACHE_PREFIX").size).to eq(1)
      expect(response.body).not_to include("importScripts", "OP_SW")
    end

    it "registers no worker" do
      get "/login"

      expect(page).to have_no_css(controller_selector, visible: :all)
    end
  end
end

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
  shared_context "with a relative url root" do
    around do |example|
      previous = OpenProject::Configuration["rails_relative_url_root"]
      OpenProject::Configuration["rails_relative_url_root"] = "/openproject"
      example.run
    ensure
      OpenProject::Configuration["rails_relative_url_root"] = previous
    end
  end

  let(:helper_cache_name) do
    ApplicationController.helpers.pwa_shell_cache_name
  end
  let(:controller_selector) { 'body[data-controller~="pwa-service-worker"]' }

  it "does not route a format suffix" do
    expect { get "/service-worker.js" }.to raise_error(ActionController::RoutingError)
  end

  describe "GET /service-worker", with_settings: { login_required: true } do
    before do
      allow(FrontendAssetHelper).to receive(:assets_proxied?).and_return(false)
      get "/service-worker"
    end

    it "is served as JavaScript to a visitor without a session" do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end

    it "takes control of its clients" do
      expect(response.body).to include("skipWaiting", "clients.claim")
    end

    it "caches the shell under a versioned name and intercepts only fetches" do
      expect(response.body).to include(helper_cache_name)
      expect(response.body).to include("/assets/frontend/")
      expect(response.body).to include('addEventListener("fetch"')
      expect(response.body).not_to include("push")
    end

    it "precaches the offline page without credentials and shows it for failed navigations" do
      expect(response.body).to include('"/offline"', 'credentials: "omit"', 'request.mode === "navigate"')
      expect(response.body).to include("navigationPreload")
    end

    context "when the dev proxy serves the assets" do
      before do
        allow(FrontendAssetHelper).to receive(:assets_proxied?).and_return(true)
        get "/service-worker"
      end

      it "still precaches the offline page but no assets" do
        expect(response.body).to include('"/offline"')
        expect(response.body).to include("const PRECACHE = []")
      end

      # The offline page is shown without a network, so its logo must come from the cache too.
      it "serves the offline page's images from the cache without caching other assets" do
        expect(response.body).to include("const CACHE_HASHED_ASSETS = false")
        expect(response.body).to match(%r{const CACHED_PATHS = \[[^\]]*"/assets/logo_openproject_white_big\.png"})
      end
    end
  end

  describe "the registration wiring" do
    before { login_as create(:user) }

    it "registers the worker for the whole instance" do
      get "/my/page"

      expect(page).to have_css(controller_selector, visible: :all)
      expect(page).to have_css('body[data-pwa-service-worker-url-value="/service-worker"]', visible: :all)
      expect(page).to have_css('body[data-pwa-service-worker-scope-value="/"]', visible: :all)
    end

    it "tells the controller the user is signed in" do
      get "/my/page"

      expect(page).to have_css('body[data-pwa-service-worker-signed-in-value="true"]', visible: :all)
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

  it "tells the controller an anonymous visitor is signed out" do
    get "/login"

    expect(page).to have_css('body[data-pwa-service-worker-signed-in-value="false"]', visible: :all)
  end

  it "registers the worker on the logo-only layout too" do
    get "/404"

    expect(page).to have_css(controller_selector, visible: :all)
  end

  context "with the feature flag off", with_flag: { progressive_web_app: false } do
    it "serves a worker that removes the shell caches and unregisters itself" do
      get "/service-worker"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include("openproject-shell-", "unregister")
      expect(response.body).not_to include("fetch")
    end

    it "registers no worker" do
      get "/login"

      expect(page).to have_no_css(controller_selector, visible: :all)
    end
  end
end

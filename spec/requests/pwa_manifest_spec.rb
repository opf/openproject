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
require "mini_magick"

RSpec.describe "PWA manifest", type: :rails_request, with_flag: { progressive_web_app: true } do
  subject(:manifest) { response.parsed_body }

  shared_context "with a relative url root" do
    around do |example|
      previous = OpenProject::Configuration["rails_relative_url_root"]
      OpenProject::Configuration["rails_relative_url_root"] = "/openproject"
      example.run
    ensure
      OpenProject::Configuration["rails_relative_url_root"] = previous
    end
  end

  describe "GET /manifest", with_settings: { login_required: true, app_title: "Acme Projects" } do
    before { get "/manifest" }

    it "is served as JSON to a visitor without a session" do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
    end

    it "is served as JSON when the browser asks for HTML" do
      get "/manifest", headers: { "Accept" => "text/html" }

      expect(response.media_type).to eq("application/json")
    end

    it "installs as a standalone window named after the instance, rooted at the instance" do
      expect(manifest).to include("name" => "Acme Projects",
                                  "display" => "standalone",
                                  "id" => "/",
                                  "start_url" => "/",
                                  "scope" => "/")
    end

    it "paints the window in the default header colour" do
      expect(manifest).to include("theme_color" => "#1A67A3")
    end

    # Chrome silently declines to install when an icon is missing or mis-sized.
    it "names icons that exist at the size they declare" do
      icons = manifest["icons"]
      expect(icons.pluck("sizes")).to include("192x192", "512x512")

      icons.each do |icon|
        get icon["src"]

        expect(response).to have_http_status(:ok), "#{icon['src']} is not served"
        image = MiniMagick::Image.read(response.body)
        expect("#{image.width}x#{image.height}").to eq(icon["sizes"])
      end
    end
  end

  context "with a custom header colour" do
    before do
      create(:custom_style)
      DesignColor.create!(variable: "header-bg-color", hexcode: "#123456")
      get "/manifest"
    end

    it "paints the window in it", with_ee: %i[define_custom_style] do
      expect(manifest).to include("theme_color" => "#123456")
    end

    it "keeps the default without an enterprise token" do
      expect(manifest).to include("theme_color" => "#1A67A3")
    end
  end

  context "when served under a path prefix" do
    include_context "with a relative url root"

    before { get "/manifest", env: { "SCRIPT_NAME" => "/openproject" } }

    it "installs and launches at the prefix" do
      expect(manifest).to include("id" => "/openproject/",
                                  "start_url" => "/openproject/",
                                  "scope" => "/openproject/")
    end
  end

  describe "the document head" do
    it "links the manifest" do
      get "/login"

      expect(page).to have_css('link[rel="manifest"][href="/manifest"]', visible: :all)
    end

    context "when served under a path prefix" do
      include_context "with a relative url root"

      it "links the prefixed manifest" do
        get "/login", env: { "SCRIPT_NAME" => "/openproject" }

        expect(page).to have_css('link[rel="manifest"][href="/openproject/manifest"]', visible: :all)
      end
    end
  end

  describe "the theme-color tags" do
    let(:tags) { 'meta[name="theme-color"]' }

    def sign_in_with_theme(theme)
      login_as create(:user, preferences: { theme: })
      get "/my/page"

      expect(response).to have_http_status(:ok)
    end

    it "paints the title bar in the header colour for a light preference" do
      sign_in_with_theme("light")

      expect(page).to have_css(%(#{tags}[content="#1A67A3"]), count: 1, visible: :all)
      expect(page).to have_no_css("#{tags}[media]", visible: :all)
    end

    it "paints the title bar in the dark header colour for a dark preference" do
      sign_in_with_theme("dark")

      expect(page).to have_css(%(#{tags}[content="#010409"]), count: 1, visible: :all)
      expect(page).to have_no_css("#{tags}[media]", visible: :all)
    end

    it "follows the operating system when the preference syncs with it" do
      sign_in_with_theme("sync_with_os")

      expect(page).to have_css(%(#{tags}[media="(prefers-color-scheme: light)"][content="#1A67A3"]), visible: :all)
      expect(page).to have_css(%(#{tags}[media="(prefers-color-scheme: dark)"][content="#010409"]), visible: :all)
    end
  end

  context "with the feature flag off", with_flag: { progressive_web_app: false } do
    it "serves no manifest" do
      expect { get "/manifest" }.to raise_error(ActionController::RoutingError)
    end

    it "links no manifest" do
      get "/login"

      expect(page).to have_no_css('link[rel="manifest"]', visible: :all)
    end

    it "renders no theme-color tag" do
      get "/login"

      expect(page).to have_no_css('meta[name="theme-color"]', visible: :all)
    end
  end
end

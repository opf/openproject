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

RSpec.describe "PWA offline page",
               type: :rails_request,
               with_flag: { progressive_web_app: true },
               with_settings: { login_required: true, app_title: "Acme Projects" } do
  let(:user) { create(:user, firstname: "Zaphod", lastname: "Beeblebrox", login: "zbeeblebrox") }

  it "is served as HTML to a visitor without a session" do
    get "/offline"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
  end

  it "shows the app title and the offline copy" do
    get "/offline"

    expect(page).to have_css("h1", text: "You’re offline")
    expect(page).to have_text("Acme Projects reloads automatically as soon as your connection returns.")
    expect(page).to have_css("[data-offline-target='button']", text: "Retry")
    expect(page).to have_css("p[role='status'][aria-live='polite']", visible: :all)
  end

  it "exposes the script contract on the root element" do
    get "/offline"

    expect(page).to have_css("main[data-offline-page][data-state='offline'][data-retrying-label='Retrying…']")
  end

  it "references nothing outside the instance" do
    get "/offline"

    expect(response.body).not_to match(%r{https?://|(src|href)=["']//|url\(["']?//})
  end

  it "inlines the script under the response's nonce" do
    get "/offline"

    nonce = response.headers["Content-Security-Policy"][/script-src[^;]*'nonce-([^']+)'/, 1]
    expect(nonce).to be_present
    expect(page).to have_css("script[nonce='#{nonce}']", visible: :all)
  end

  it "contains no user data for a signed in user" do
    login_as user
    get "/offline"

    expect(response.body).not_to include("Zaphod", "zbeeblebrox")
    expect(page).to have_no_css("meta[name='csrf-token'], meta[name='current_user']", visible: :all)
  end

  it "renders in the requested language, falling back to English for untranslated copy" do
    get "/offline", headers: { "Accept-Language" => "de" }

    expect(page).to have_css("html[lang='de']")
    expect(page).to have_css("h1", text: "You’re offline")
  end

  it "uses the default logo without custom styles" do
    get "/offline"

    expect(page).to have_css("img[src*='logo_openproject_white_big']", visible: :all)
  end

  context "with a custom logo", with_ee: %i[define_custom_style] do
    let(:custom_style) { create(:custom_style_with_logo) }

    before do
      custom_style
      get "/offline"
    end

    it "uses the custom logo" do
      expect(page).to have_css("img[src^='/custom_style/#{custom_style.digest}/logo/']", visible: :all)
    end
  end

  context "with the feature flag off", with_flag: { progressive_web_app: false } do
    it "is not routed" do
      expect { get "/offline" }.to raise_error(ActionController::RoutingError)
    end
  end
end

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

RSpec.describe "Frontend dev server redirect", type: :rails_request do
  let(:asset_path) { "/assets/frontend/assets/images/notification-center/empty-state-no-notification_light.svg" }

  before do
    allow(FrontendAssetHelper).to receive_messages(assets_proxied?: proxied, cli_proxy: "http://localhost:4200")
  end

  context "when frontend assets are proxied to the dev server" do
    let(:proxied) { true }

    it "redirects frontend assets to the dev server without the query string" do
      get "#{asset_path}?v=1"

      expect(response).to have_http_status(:temporary_redirect)
      expect(response.location).to eq("http://localhost:4200#{asset_path}")
    end
  end

  context "when frontend assets are not proxied" do
    let(:proxied) { false }

    it "leaves the request to the asset server" do
      get asset_path

      expect(response).to have_http_status(:not_found)
    end
  end
end

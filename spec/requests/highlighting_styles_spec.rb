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

RSpec.describe "highlighting styles", type: :rails_request do
  let(:color) { create(:color, hexcode: "#FF0000") }
  let!(:status) { create(:status, color:) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:version_tag) { Class.new { include HighlightingHelper }.new.highlight_css_version_tag }

  def get_styles(user:)
    login_as user
    get "/highlighting/styles/#{version_tag}"
  end

  it "declares the color of a status as custom properties" do
    get_styles(user: user)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq "text/css"
    expect(response.body).to include("__hl_status_#{status.id} { --hl-color: #FF0000;")
  end

  # The response used to be rendered inside the cache block, so a hit rendered
  # nothing at all and the request failed with ActionController::UnknownFormat.
  context "when the cache is already warm" do
    before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

    it "serves the cached stylesheet instead of rendering nothing" do
      get_styles(user: user)
      warmed = response.body

      expect(warmed).to be_present

      get_styles(user: other_user)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "text/css"
      expect(response.body).to eq warmed
    end
  end

  # The stylesheet used to branch on the requesting user's theme while being cached
  # under a key that did not include it.
  it "does not vary by the requesting user's theme" do
    dark = create(:user, preferences: { theme: "dark" })
    light = create(:user, preferences: { theme: "light" })

    get_styles(user: dark)
    dark_body = response.body

    get_styles(user: light)

    expect(response.body).to eq dark_body
  end
end

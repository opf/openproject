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
require "rack/test"

RSpec.describe "API v3 Group avatar resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { create(:admin) }
  let(:group) { create(:group) }

  subject(:response) { last_response }

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return(enable_gravatars: true, enable_local_avatars: true)

    get "#{api_v3_paths.group(group.id)}/avatar"
  end

  describe "/avatar", with_settings: { protocol: "http" } do
    context "without a local avatar" do
      it "renders a generated initials SVG, never a Gravatar redirect" do
        expect(response).to have_http_status :ok
        expect(response.content_type).to eq "image/svg+xml"
        expect(response.body).to include("<svg")
      end

      it "has the cache headers set to 24 hours" do
        expect(response.headers["Cache-Control"]).to eq "public, max-age=86400"
        expect(response.headers["Expires"]).to be_present
      end
    end

    context "with a local avatar" do
      let(:group) do
        g = create(:group)
        g.attachments = [build(:avatar_attachment, author: current_user)]
        g
      end

      it "serves the attachment file" do
        expect(response).to have_http_status :ok
      end
    end
  end
end

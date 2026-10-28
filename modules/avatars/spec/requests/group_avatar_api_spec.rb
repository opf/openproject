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
    context "with an initials override and a stored image" do
      let(:group) do
        create(:group, avatar_type: "initials", avatar_text: "🚀").tap do |principal|
          principal.attachments = [build(:avatar_attachment, author: current_user)]
        end
      end

      it "renders the override without deleting the image" do
        expect(response).to have_http_status :ok
        expect(response.content_type).to eq "image/svg+xml"
        expect(response.body).to include(">🚀<")
        expect(group.local_avatar_attachment).to be_present
      end
    end

    context "without a local avatar" do
      it "renders a generated initials SVG, never a Gravatar redirect" do
        expect(response).to have_http_status :ok
        expect(response.content_type).to eq "image/svg+xml"
        expect(response.body).to include("<svg")
      end

      it "always revalidates instead of caching blindly, since group avatars are always edited by someone else" do
        expect(response.headers["Cache-Control"]).to eq "public, max-age=0, must-revalidate"
        expect(response.headers["ETag"]).to be_present
      end
    end

    context "with a local avatar" do
      let(:avatar_type) { nil }
      let(:group) do
        g = create(:group, avatar_type:)
        g.attachments = [build(:avatar_attachment, author: current_user)]
        g
      end

      it "serves the attachment file" do
        expect(response).to have_http_status :ok
      end

      it "sets an ETag" do
        expect(response.headers["ETag"]).to be_present
      end

      context "with an explicit choice of image" do
        let(:avatar_type) { "image" }

        it "serves the uploaded image" do
          expect(response).to have_http_status :ok
          expect(response.content_type).not_to eq "image/svg+xml"
        end
      end
    end

    context "when the client already has the current version cached" do
      it "responds with 304 Not Modified instead of re-sending the image" do
        etag = response.headers["ETag"]

        get "#{api_v3_paths.group(group.id)}/avatar", nil, { "HTTP_IF_NONE_MATCH" => etag }

        expect(last_response).to have_http_status 304
      end
    end

    context "when the avatar color changes after the client cached it" do
      it "no longer matches the old ETag, so the client fetches the new image" do
        stale_etag = response.headers["ETag"]

        Groups::UpdateService.new(model: group, user: current_user).call(avatar_color: "#123456")

        get "#{api_v3_paths.group(group.id)}/avatar", nil, { "HTTP_IF_NONE_MATCH" => stale_etag }

        expect(last_response).to have_http_status :ok
        expect(last_response.headers["ETag"]).not_to eq stale_etag
      end
    end

    context "when the avatar text changes after the client cached it" do
      it "renders the updated text and invalidates the ETag" do
        stale_etag = response.headers["ETag"]

        result = Groups::UpdateService.new(model: group, user: current_user).call(avatar_text: "👩🏽‍💻")
        expect(result).to be_success

        get "#{api_v3_paths.group(group.id)}/avatar", nil, { "HTTP_IF_NONE_MATCH" => stale_etag }

        expect(last_response).to have_http_status :ok
        expect(last_response.headers["ETag"]).not_to eq stale_etag
        expect(last_response.body).to include(">👩🏽‍💻<")
      end
    end

    context "when the local avatar is deleted after the client cached it" do
      let(:group) do
        g = create(:group)
        g.attachments = [build(:avatar_attachment, author: current_user)]
        g
      end

      it "no longer matches the old ETag, so the client fetches the generated fallback" do
        stale_etag = response.headers["ETag"]

        result = Avatars::UpdateService.new(group).destroy
        expect(result).to be_success

        get "#{api_v3_paths.group(group.id)}/avatar", nil, { "HTTP_IF_NONE_MATCH" => stale_etag }

        expect(last_response).to have_http_status :ok
        expect(last_response.headers["ETag"]).not_to eq stale_etag
        expect(last_response.content_type).to eq "image/svg+xml"
      end
    end

    context "when the administrator disables local avatars after the client cached the image" do
      let(:group) do
        g = create(:group, avatar_type: "image")
        g.attachments = [build(:avatar_attachment, author: current_user)]
        g
      end

      it "no longer matches the old ETag, so the client fetches the generated fallback" do
        stale_etag = response.headers["ETag"]
        allow(Setting)
          .to receive(:plugin_openproject_avatars)
          .and_return(enable_gravatars: true, enable_local_avatars: false)

        get "#{api_v3_paths.group(group.id)}/avatar", nil, { "HTTP_IF_NONE_MATCH" => stale_etag }

        expect(last_response).to have_http_status :ok
        expect(last_response.content_type).to eq "image/svg+xml"
      end
    end
  end

  describe "/avatar?source=image" do
    let(:group) do
      create(:group, avatar_type: "initials").tap do |principal|
        principal.attachments = [build(:avatar_attachment, author: current_user)]
      end
    end

    before do
      get "#{api_v3_paths.group(group.id)}/avatar?source=image"
    end

    it "serves the stored image to an administrator while initials are selected" do
      expect(last_response).to have_http_status :ok
      expect(last_response.content_type).not_to eq "image/svg+xml"
      expect(last_response.headers["Cache-Control"]).not_to include "public"
    end

    context "as a non-admin" do
      let(:current_user) { create(:user, global_permissions: %i[view_all_principals]) }

      it "does not serve the stored image" do
        expect(last_response).to have_http_status :not_found
      end
    end
  end
end

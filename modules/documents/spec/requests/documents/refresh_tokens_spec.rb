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

RSpec.describe "Document token refresh",
               :skip_csrf,
               type: :rails_request,
               with_settings: { real_time_text_collaboration_enabled: true } do
  let(:project) { create(:project, public: false) }
  let(:document) { create(:document, project:) }
  let(:role) { create(:project_role, permissions: %i[view_project view_documents]) }
  let(:user) { create(:user, member_with_roles: { project => role }) }
  let(:path) { "/projects/#{project.id}/documents/#{document.id}/refresh_token" }

  def request_token
    post path, headers: { "CONTENT_TYPE" => "application/json" }
  end

  context "when logged out and login is required", with_settings: { login_required: true } do
    it "responds with 401" do
      request_token

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when logged out, login is not required and the project is private", with_settings: { login_required: false } do
    it "responds with 404" do
      request_token

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when logged in as a non-member" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "responds with 404" do
      request_token

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when logged in as a member without view_documents" do
    let(:role) { create(:project_role, permissions: %i[view_project]) }

    before { login_as(user) }

    it "responds with 403" do
      request_token

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when logged in with access and the document does not exist" do
    let(:path) { "/projects/#{project.id}/documents/999999/refresh_token" }

    before { login_as(user) }

    it "responds with 404" do
      request_token

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when logged in with view_documents" do
    before do
      login_as(user)
      allow(Setting)
        .to receive(:collaborative_editing_hocuspocus_secret)
        .and_return("test_secret_for_encryption")
    end

    it "responds with 200 and an encrypted token" do
      request_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key("encrypted_token")
    end
  end
end

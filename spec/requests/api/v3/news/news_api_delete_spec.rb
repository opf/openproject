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

require "spec_helper"

RSpec.describe API::V3::News::NewsAPI, "delete" do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:news) { create(:news, project:, title: "foo") }

  let(:send_request) do
    header "Content-Type", "application/json"
  end

  let(:path) { api_v3_paths.news(news.id) }
  let(:parsed_response) { JSON.parse(last_response.body) }

  current_user { user }

  RSpec.shared_examples "deletion allowed" do
    it "deletes the news" do
      expect(last_response.status).to eq 204
      expect { news.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with a non-existent news" do
      let(:path) { api_v3_paths.news 1337 }

      it_behaves_like "not found"
    end
  end

  RSpec.shared_examples "deletion is not allowed" do |status|
    it "does not delete the user" do
      expect(last_response.status).to eq status
      expect(News).to exist(news.id)
    end
  end

  before do
    header "Content-Type", "application/json"
    delete path
  end

  context "when admin" do
    let(:user) { build_stubbed(:admin) }

    it_behaves_like "deletion allowed"
  end

  context "when locked admin" do
    let(:user) { build_stubbed(:admin, status: Principal.statuses[:locked]) }

    it_behaves_like "deletion is not allowed", 404
  end

  context "when non-admin" do
    let(:user) { build_stubbed(:user, admin: false) }

    it_behaves_like "deletion is not allowed", 404
  end

  context "when user with manage_news permission" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_news manage_news] }) }

    it_behaves_like "deletion allowed"
  end

  context "when anonymous user" do
    let(:user) { create(:anonymous) }

    context "when login_required", with_settings: { login_required: true } do
      it_behaves_like "error response",
                      401,
                      "Unauthenticated",
                      I18n.t("api_v3.errors.code_401")
    end

    context "when not login_required", with_settings: { login_required: false } do
      it_behaves_like "deletion is not allowed", 404
    end
  end
end

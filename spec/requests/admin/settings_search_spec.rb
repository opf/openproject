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

require "spec_helper"

RSpec.describe "Admin settings search", type: :rails_request do
  before { login_as(user) }

  context "as an admin" do
    let(:user) { create(:admin) }

    it "renders the filterable tree in its turbo frame, loading the tree from the server", :aggregate_failures do
      get admin_settings_search_path

      expect(response).to have_http_status(:ok)
      frame = response.parsed_body.at_css("turbo-frame##{Admin::SettingsSearchComponent::FRAME_ID}")
      expect(frame.at_css("filterable-tree-view")["src"]).to eq tree_admin_settings_search_path
    end

    it "renders the tree filtered by the query", :aggregate_failures do
      get tree_admin_settings_search_path, params: { query: "application title" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("/admin/settings/general?highlight=app_title")
      expect(response.body).not_to include("highlight=host_name")
    end
  end

  context "as a regular user" do
    let(:user) { create(:user) }

    it "is forbidden", :aggregate_failures do
      get admin_settings_search_path
      expect(response).to have_http_status(:forbidden)

      get tree_admin_settings_search_path
      expect(response).to have_http_status(:forbidden)
    end
  end
end

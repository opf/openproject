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

RSpec.describe "Test management admin settings", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  it "is admin only" do
    login_as(user)

    get test_management_admin_settings_path

    expect(response).to have_http_status(:forbidden)
  end

  context "as admin" do
    before { login_as(admin) }

    it "shows and updates the default display prefix" do
      get test_management_admin_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="default_display_prefix"')
      expect(response.body).not_to include("tm-admin-import-placeholders")
      expect(response.body).not_to include("Open core GitHub or GitLab")

      patch test_management_admin_settings_path, params: { default_display_prefix: "QA" }

      expect(response).to redirect_to(test_management_admin_settings_path)
      expect(Setting.plugin_openproject_test_management["default_display_prefix"]).to eq("QA")
    end

    it "does not touch other module settings" do
      Setting.plugin_openproject_test_management = { "default_display_prefix" => "QA", "other" => "kept" }

      patch test_management_admin_settings_path, params: { default_display_prefix: "ZZ", other: "lost" }

      expect(Setting.plugin_openproject_test_management).to include("default_display_prefix" => "ZZ", "other" => "kept")
    end

    it "rejects a default display prefix that is too long" do
      too_long = "x" * (TestManagement::ProjectSetting::DISPLAY_PREFIX_MAX_LENGTH + 1)

      patch test_management_admin_settings_path, params: { default_display_prefix: too_long }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Setting.plugin_openproject_test_management["default_display_prefix"]).not_to eq(too_long)
    end
  end
end

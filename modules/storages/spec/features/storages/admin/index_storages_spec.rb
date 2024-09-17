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
require_module_spec_helper

RSpec.describe "Admin List File storages",
               :js,
               :storage_server_helpers do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }

  current_user { admin }

  context "with storages" do
    shared_let(:nextcloud_storage) { create(:nextcloud_storage) }
    shared_let(:one_drive_storage) { create(:one_drive_storage) }

    before do
      visit admin_settings_storages_path
    end

    it "renders a list of all storages" do
      within :css, "#content" do
        expect(page).to have_list_item(nextcloud_storage.name)
        expect(page).to have_list_item(one_drive_storage.name)
      end
    end

    it "renders content that is accessible" do
      expect(page)
        .to be_axe_clean
              .within("#content")
              .excluding("opce-principal")
    end
  end

  context "with no storages" do
    before do
      visit admin_settings_storages_path
    end

    it "renders a blank slate" do
      expect(page).to have_title("Files")
      expect(page.find(".PageHeader-title")).to have_text("External file storages")
      expect(page).to have_text("You don't have any storages yet.")
    end

    it "renders content that is accessible" do
      expect(page).to be_axe_clean.within("#content")
    end
  end
end

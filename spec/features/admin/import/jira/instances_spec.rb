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

RSpec.describe "Jira instance configuration", :js do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "new form" do
    before { visit new_admin_import_jira_path }

    it "does not restore form values when navigating back after a successful creation" do
      fill_in "Name", with: "My Jira"
      fill_in "Jira Server/Data Center URL", with: "https://jira.example.com"
      fill_in "Personal Access Token", with: "secret_token"

      click_on "Add configuration"

      expect(page).to have_current_path(%r{/admin/import/jira/\d+})

      page.execute_script("window.history.back()")

      expect(page).to have_current_path(new_admin_import_jira_path)
      expect(page).to have_field("Name", with: "")
      expect(page).to have_field("Jira Server/Data Center URL", with: "")
      expect(page).to have_field("Personal Access Token", with: "")
    end

    it "shows an error when name is blank" do
      fill_in "Jira Server/Data Center URL", with: "https://jira.example.com"
      fill_in "Personal Access Token", with: "secret_token"
      click_on "Add configuration"

      expect(page).to have_text("Jira instance name can't be blank")
    end

    it "shows an error when URL is blank" do
      fill_in "Name", with: "My Jira"
      fill_in "Personal Access Token", with: "secret_token"
      click_on "Add configuration"

      expect(page).to have_text("URL can't be blank")
    end

    it "shows an error when personal access token is blank" do
      fill_in "Name", with: "My Jira"
      fill_in "Jira Server/Data Center URL", with: "https://jira.example.com"
      click_on "Add configuration"

      expect(page).to have_text("Personal access token can't be blank")
    end
  end

  describe "edit form" do
    let!(:jira) { create(:jira, name: "My Jira", id: 9) }

    before { visit edit_admin_import_jira_path(jira) }

    it "shows the masked token with a delete button when a token is present" do
      expect(page).to have_field("Personal Access Token", with: "*********", disabled: true)
      expect(page).to have_css("[href='/admin/import/jira/9/delete_token']")
    end

    it "deletes the token and shows the token input field" do
      accept_confirm do
        find("[href='/admin/import/jira/9/delete_token']").click
      end

      expect(page).to have_field("Personal Access Token", disabled: false)
      expect(jira.reload.personal_access_token).to be_nil
    end

    it "shows an error when saving without a name" do
      fill_in "Name", with: ""
      click_on "Save configuration"

      expect(page).to have_text("Jira instance name can't be blank")
    end
  end
end

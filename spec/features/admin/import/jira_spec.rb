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

RSpec.describe "Jira instance configuration", :js do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "new form", :webmock do
    include_context "with Jira connection stubs"

    before { visit new_admin_import_jira_path }

    it "explains the credential requirements and offers a Test Connection button" do
      expect(page).to have_button("Test Connection")
      expect(page).to have_text("Requirements for the Jira user behind the credentials")
      expect(page).to have_text("The user must be a Jira administrator.")
      expect(page).to have_text("The user must be a member of every Jira project you want to migrate.")
      expect(page).to have_text("The token must belong to a Jira administrator.")
    end

    it "cancels back to the Jira import overview" do
      click_on "Cancel"

      expect(page).to have_current_path(admin_import_jira_index_path)
    end

    it "does not restore form values when navigating back after a successful creation" do
      expect(page).to have_unchecked_field("Exclude resolution fields for this configuration")

      fill_in "Name", with: "My Jira"
      fill_in "Jira Server/Data Center URL", with: url
      fill_in "Personal access token (PAT)", with: "secret_token"
      check "Exclude resolution fields for this configuration"

      click_on "Add configuration"

      expect(page).to have_current_path(%r{/admin/import/jira/\d+})

      page.execute_script("window.history.back()")

      expect(page).to have_current_path(new_admin_import_jira_path)
      expect(page).to have_field("Name", with: "")
      expect(page).to have_field("Jira Server/Data Center URL", with: "")
      expect(page).to have_field("Personal access token (PAT)", with: "")
      expect(page).to have_unchecked_field("Exclude resolution fields for this configuration")
    end

    it "has extra configuration options" do
      expect(page).to have_unchecked_field("Exclude resolution fields for this configuration")

      check "Exclude resolution fields for this configuration"
      click_on "Add configuration"

      expect(page).to have_checked_field("Exclude resolution fields for this configuration")
    end

    it "shows an error when name is blank" do
      fill_in "Jira Server/Data Center URL", with: "https://jira.example.com"
      fill_in "Personal access token (PAT)", with: "secret_token"
      click_on "Add configuration"

      expect(page).to have_text("Jira instance name can't be blank")
    end

    it "shows an error when URL is blank" do
      fill_in "Name", with: "My Jira"
      fill_in "Personal access token (PAT)", with: "secret_token"
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

    it "shows the masked token with a delete button and the administrator caption when a token is present" do
      expect(page).to have_field("Personal access token (PAT)", with: "*********", disabled: true)
      expect(page).to have_css("[href='/admin/import/jira/9/clear_credential?field=personal_access_token']")
      expect(page).to have_css(".FormControl-caption", text: "The token must belong to a Jira administrator.")
    end

    it "deletes the token, confirms the deletion and shows the token input field" do
      accept_confirm do
        find("[href='/admin/import/jira/9/clear_credential?field=personal_access_token']").click
      end

      expect_flash(message: "Personal access token (PAT) was successfully deleted.")
      expect(page).to have_field("Personal access token (PAT)", type: "text", disabled: false)
      expect(jira.reload.personal_access_token).to be_nil
    end

    it "shows an error when saving without a name" do
      fill_in "Name", with: ""
      click_on "Save configuration"

      expect(page).to have_text("Jira instance name can't be blank")
    end

    it "has extra configuration options" do
      expect(page).to have_unchecked_field("Exclude resolution fields for this configuration")

      check "Exclude resolution fields for this configuration"
      click_on "Save configuration"
      visit edit_admin_import_jira_path(jira)

      expect(page).to have_checked_field("Exclude resolution fields for this configuration")
    end
  end

  describe "connection check", :webmock do
    include_context "with Jira connection stubs"

    it "saves the configuration when pressing Enter in a field" do
      visit new_admin_import_jira_path

      fill_in "Name", with: "My Jira"
      fill_in "Jira Server/Data Center URL", with: url
      fill_in "Personal access token (PAT)", with: "token"
      find_field("Name").send_keys(:enter)

      expect(page).to have_text(I18n.t(:notice_successful_create))
      expect(Import::Jira.pluck(:name)).to eq(["My Jira"])
    end

    it "saves without checking the connection when only the name changes" do
      jira = create(:jira, name: "My Jira", url:)

      visit edit_admin_import_jira_path(jira)
      fill_in "Name", with: "Renamed"
      click_on "Save configuration"

      expect(page).to have_text(I18n.t(:notice_successful_update))
      expect(server_info_request).not_to have_been_requested
    end

    context "when Jira rejects the credentials" do
      before { stub_request(:get, "#{url}/rest/api/2/mypermissions").to_return(status: 401) }

      it "checks the form values in the side panel without saving them" do
        visit new_admin_import_jira_path

        expect(page).to have_text("Not checked yet.")

        fill_in "Jira Server/Data Center URL", with: url
        fill_in "Personal access token (PAT)", with: "wrong_token"
        click_on "Test Connection"

        expect(page).to have_text("Checked the values in the form. They are not saved yet.")
        expect(page).to have_text("ERR_CREDENTIALS_REJECTED")
        expect(page).to have_button("Test Connection", disabled: false)
        expect(Import::Jira.count).to eq(0)
      end

      it "shows the latest stored check on the edit form" do
        jira = create(:jira, name: "My Jira", url:)
        Import::Jiras::CheckConnectionService.new(jira).call

        visit edit_admin_import_jira_path(jira)

        expect(page).to have_text("Last check:")
        expect(page).to have_text("ERR_CREDENTIALS_REJECTED")
      end

      it "checks the stored configuration from the edit form" do
        jira = create(:jira, name: "My Jira", url:)

        visit edit_admin_import_jira_path(jira)
        click_on "Test Connection"

        expect(page).to have_text("Checked the values in the form. They are not saved yet.")
        expect(page).to have_text("ERR_CREDENTIALS_REJECTED")
      end

      it "saves a new configuration and shows the failed check on its edit form" do
        visit new_admin_import_jira_path

        fill_in "Name", with: "My Jira"
        fill_in "Jira Server/Data Center URL", with: url
        fill_in "Personal access token (PAT)", with: "wrong_token"
        click_on "Add configuration"

        within_modal "Connection check failed" do
          expect(page).to have_text("The configuration is saved, but the check Credentials accepted failed.")
        end
        expect(page).to have_current_path(edit_admin_import_jira_path(Import::Jira.sole))
        expect(page).to have_text("Last check:")
        expect(page).to have_text("ERR_CREDENTIALS_REJECTED")
      end

      context "when saving a changed URL" do
        let(:jira) { create(:jira, name: "My Jira", url: "https://old.example.com") }

        before do
          visit edit_admin_import_jira_path(jira)
          fill_in "Jira Server/Data Center URL", with: url
          click_on "Save configuration"
        end

        it "keeps the form and the report when choosing to fix the configuration" do
          within_modal("Connection check failed") { click_on "Fix configuration" }

          expect(page).to have_no_modal "Connection check failed"
          expect(page).to have_current_path(edit_admin_import_jira_path(jira))
          expect(page).to have_text("ERR_CREDENTIALS_REJECTED")
        end

        it "goes to the configuration page when continuing anyway" do
          within_modal("Connection check failed") { click_on "Continue anyway" }

          expect(page).to have_current_path(admin_import_jira_path(jira))
          expect(jira.reload.url).to eq(url)
        end
      end
    end
  end
end

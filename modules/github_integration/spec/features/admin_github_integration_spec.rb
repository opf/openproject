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
require "support/components/autocompleter/ng_select_autocomplete_helpers"

RSpec.describe "Admin GitHub Integration settings", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  current_user { create(:admin) }

  describe "deploy targets page" do
    it "renders the page" do
      visit deploy_targets_path

      expect(page).to have_content("GitHub Integration")
    end
  end

  describe "settings page" do
    shared_let(:github_actor) { create(:user, firstname: "GitHub", lastname: "Actor") }

    before do
      Setting.plugin_openproject_github_integration = {}
      visit github_integration_admin_settings_path
    end

    it "shows a warning banner when no webhook secret is configured" do
      expect(page).to have_text I18n.t(:text_github_webhook_secret_missing_warning)
    end

    it "saves the webhook secret" do
      fill_in I18n.t(:label_github_webhook_secret), with: "my-super-secret"
      click_button I18n.t(:button_save)

      expect(page).to have_content(I18n.t(:notice_successful_update))

      Setting.clear_cache
      expect(Setting.plugin_openproject_github_integration["webhook_secret"]).to eq("my-super-secret")
    end

    it "does not show the warning banner after a webhook secret is saved" do
      expect(page).to have_text I18n.t(:text_github_webhook_secret_missing_warning)
      fill_in I18n.t(:label_github_webhook_secret), with: "my-super-secret"
      click_button I18n.t(:button_save)

      expect(page).to have_no_text I18n.t(:text_github_webhook_secret_missing_warning)
    end

    it "saves the GitHub actor user" do
      github_actor # ensure user exists

      select_autocomplete find("opce-user-autocompleter"),
                          query: github_actor.name,
                          results_selector: "body"

      click_button I18n.t(:button_save)

      expect(page).to have_content(I18n.t(:notice_successful_update))

      Setting.clear_cache
      expect(Setting.plugin_openproject_github_integration["github_user_id"]).to eq(github_actor.id.to_s)
    end

    it "displays the currently saved actor after reload" do
      Setting.plugin_openproject_github_integration = { "github_user_id" => github_actor.id.to_s,
                                                        "webhook_secret" => "existing-secret" }

      visit github_integration_admin_settings_path

      expect(page).to have_css("opce-user-autocompleter .ng-value", text: github_actor.name)
      expect(page).to have_field(I18n.t(:label_github_webhook_secret), with: "existing-secret")
    end
  end
end

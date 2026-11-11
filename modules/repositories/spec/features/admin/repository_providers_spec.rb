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
require "support/components/autocompleter/ng_select_autocomplete_helpers"

RSpec.describe "Admin repository providers", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  current_user { create(:admin) }

  shared_let(:webhook_user) { create(:user, firstname: "GitLab", lastname: "Actor") }

  it "sets up a GitLab provider with the wizard" do
    visit admin_settings_repository_providers_path
    expect(page).to have_text(I18n.t("repositories.admin.table.blank_title"))

    page.find_test_selector("repository-providers-create-new-button", match: :first).click
    click_on "GitLab"

    fill_in "Name", with: "Our GitLab"
    fill_in "GitLab URL", with: "https://gitlab.example.com"
    click_on I18n.t("repositories.admin.buttons.save_and_continue")

    select_autocomplete find("opce-user-autocompleter"), query: webhook_user.name, results_selector: "body"
    click_on I18n.t("repositories.admin.buttons.save_and_continue")

    expect(page).to have_field("webhook_secret", readonly: true)
    provider = Repositories::GitlabProvider.find_by!(name: "Our GitLab")
    expect(page).to have_field("webhook_secret", with: provider.webhook_secret)
    expect(provider.gitlab_user_id).to eq(webhook_user.id)

    click_on I18n.t(:button_finish_setup)

    expect(page).to have_current_path(edit_admin_settings_repository_provider_path(provider))
    expect(page).to have_text(I18n.t("repositories.admin.steps.webhook_user.description_user", name: webhook_user.name))
  end

  context "with an existing provider" do
    let!(:provider) do
      create(:repository_provider, name: "Our GitLab", gitlab_user_id: webhook_user.id, webhook_secret: "old-secret")
    end

    it "edits the general information" do
      visit edit_admin_settings_repository_provider_path(provider)

      page.find_test_selector("repository-provider-edit-general_information-button").click
      fill_in "Name", with: "Renamed GitLab"
      click_on I18n.t(:button_save)

      expect(page).to have_text("Renamed GitLab")
      expect(provider.reload.name).to eq("Renamed GitLab")
    end

    it "removes the webhook user" do
      visit edit_admin_settings_repository_provider_path(provider)

      page.find_test_selector("repository-provider-edit-webhook_user-button").click
      expect(page).to have_css("opce-user-autocompleter .ng-value", text: webhook_user.name)
      find("opce-user-autocompleter .ng-clear-wrapper").click
      click_on I18n.t(:button_save)

      expect(page).to have_text(I18n.t("repositories.admin.steps.webhook_user.description_any_user"))
      expect(provider.reload.gitlab_user_id).to be_nil
    end

    it "regenerates the webhook secret" do
      visit edit_admin_settings_repository_provider_path(provider)

      page.find_test_selector("repository-provider-edit-webhook-button").click
      expect(page).to have_field("webhook_secret", with: "old-secret", readonly: true)

      click_on I18n.t("repositories.admin.steps.webhook.regenerate_secret")
      within_test_selector("repository-provider-regenerate-webhook-secret-dialog") do
        click_on I18n.t("repositories.admin.regenerate_webhook_secret_dialog_component.confirm_button")
      end

      expect(page).to have_no_test_selector("repository-provider-regenerate-webhook-secret-dialog")
      expect(page).to have_no_field("webhook_secret", with: "old-secret")
      expect(provider.reload.webhook_secret).not_to eq("old-secret")
    end

    it "deletes the provider" do
      visit edit_admin_settings_repository_provider_path(provider)

      page.find_test_selector("repository-provider-delete-button", match: :first).click
      within_test_selector("repository-provider-destroy-dialog") do
        expect(page).to have_button(I18n.t(:button_delete_permanently), disabled: true)

        check I18n.t(:text_permanent_delete_confirmation_checkbox_label)
        expect(page).to have_button(I18n.t(:button_delete_permanently), disabled: false)

        click_on I18n.t(:button_delete_permanently)
      end

      expect(page).to have_text(I18n.t(:notice_successful_delete))
      expect(Repositories::Provider).not_to exist
    end
  end
end

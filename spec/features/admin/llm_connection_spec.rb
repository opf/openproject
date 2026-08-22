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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

# The markup on these pages is hand-written rather than generated, so this spec
# exists mainly to put it through axe. The row toggle in particular has no
# accessible name of its own and depends on an explicit aria-label.
# :selenium is required, not incidental: axe-core-api drives the browser through
# Selenium's #manage API, so be_axe_clean does not work under cuprite. Every other
# axe spec in this repository is tagged the same way for the same reason.
RSpec.describe "LLM connection administration",
               :js, :llm_server_helpers, :selenium, :webmock,
               driver: :firefox_de,
               with_flag: { llm_connection: true } do
  shared_let(:admin) { create(:admin) }

  let(:base_url) { "https://example.com/v1" }

  current_user { admin }

  # The kebab is a Primer ActionMenu: clicking it before its behaviour is
  # attached silently does nothing, so wait for the page to settle first and
  # for the item itself to become visible.
  def offered_default_models(field = :default_chat_model_id)
    element = all("[data-test-selector='llm-connection--defaults-form'] opce-autocompleter")
                .find { |node| node["data-input-name"].include?(field.to_s) }

    JSON.parse(element["data-items"]).pluck("id").compact_blank
  end

  def choose_action(item)
    expect(page).to have_test_selector("llm-connection--actions")
    find_test_selector("llm-connection--actions").click
    expect(page).to have_test_selector(item)
    find_test_selector(item).click
  end

  context "when nothing is configured yet" do
    it "renders an accessible, empty settings page" do
      visit llm_connection_path

      check "Enable LLMs for this instance"

      expect(page).to have_field("Host URL")
      expect(page).to be_axe_clean.within("#content")
    end

    it "hides the server settings until the connection is enabled" do
      visit llm_connection_path

      expect(page).to have_field("Host URL", visible: :hidden)

      check "Enable LLMs for this instance"

      expect(page).to have_field("Host URL")
    end

    it "offers the models and feature tabs only once the connection is enabled" do
      mock_llm_models_response(base_url)

      visit llm_connection_path

      expect(page).to have_no_test_selector("llm-settings--tabs")

      check "Enable LLMs for this instance"
      fill_in "Host URL", with: base_url
      click_on "Connect"

      expect(page).to have_test_selector("llm-settings--tabs")

      within_test_selector("llm-settings--tabs") { click_on "LLMs" }

      expect(page).to have_current_path(llm_models_path)

      within_test_selector("llm-settings--tabs") { click_on "Feature configuration" }

      expect(page).to have_current_path(llm_feature_bindings_path)
    end

    it "describes the server the selected API format expects" do
      visit llm_connection_path

      check "Enable LLMs for this instance"

      expect(page).to have_text("speaks the OpenAI API")

      select "Anthropic", from: "API format"

      expect(page).to have_text("speaks the Anthropic API")
      expect(page).to have_no_text("speaks the OpenAI API")
    end
  end

  context "when a key is stored" do
    let!(:connection) { create(:llm_connection, base_url:, api_key: "sk-original") }

    it "removes the key from beside the field" do
      visit llm_connection_path

      expect(page).to have_field("API key", placeholder: "API key stored")

      find_test_selector("llm-connection--remove-api-key").click

      within_test_selector("llm-connection--delete-api-key-dialog") do
        click_on "Remove API key"
      end

      expect(page).to have_no_test_selector("llm-connection--remove-api-key")
      expect(page).to have_field("API key", placeholder: nil)
      expect(connection.reload.api_key).to be_nil
    end
  end

  context "with a configured connection" do
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }

    before { mock_llm_models_response(base_url) }

    it "renders the model list accessibly" do
      create(:llm_model,
             llm_connection: connection,
             external_id: "publisher/a-very-long-model-name-that-does-not-fit-the-column-32b-instruct-2026-05")

      visit llm_models_path

      expect(page).to have_test_selector("llm-model--refresh-button")
      expect(page).to have_text(connection.models.first.external_id)
      expect(page).to have_test_selector("llm-model--toggle-#{connection.models.first.id}")
      expect(page).to be_axe_clean.within("#content")
    end

    it "hides a model from the feature pickers when it is switched off" do
      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")

      visit llm_models_path

      expect(offered_default_models).to include("qwen3.6-27b")

      find_test_selector("llm-model--toggle-#{llm_model.id}").click

      wait_for { llm_model.reload.deactivated_at }.not_to be_nil
      wait_for { offered_default_models }.not_to include("qwen3.6-27b")

      # The toggle re-renders the pickers, not the row, so the table itself only
      # catches up on the next load.
      visit llm_models_path

      within_test_selector("llm-model--toggle-#{llm_model.id}") do
        expect(page).to have_css("button[aria-pressed='false']")
      end
      expect(page).to have_no_text("Hidden")
    end

    # The chat capabilities are hidden client-side, so only a browser shows that
    # the type choice actually reaches them.
    it "adds a model by hand and offers the capabilities its type can have" do
      visit llm_models_path
      expect(page).to have_test_selector("llm-model--refresh-button")

      find_test_selector("llm-model--add-button").click

      expect(page).to have_field("Model name")
      expect(page).to be_axe_clean.within("#content")
      expect(page).to have_field("Tool calling")

      fill_in "Model name", with: "nomic-embed-text"
      select "Embedding model", from: "Model type"

      expect(page).to have_field("Tool calling", visible: :hidden)

      click_on "+ Model"

      expect(page).to have_current_path(llm_models_path)
      expect(page).to have_text("nomic-embed-text")
      expect(connection.models.find_by(external_id: "nomic-embed-text")).to be_embedding
    end

    it "removes the stored API key" do
      visit llm_connection_path
      expect(page).to have_field("Host URL")

      choose_action("llm-connection--delete-api-key")

      within_test_selector("llm-connection--delete-api-key-dialog") do
        # The muted description and the danger button label Primer renders around
        # our content miss the 4.5:1 contrast ratio, app-wide.
        expect(page).to be_axe_clean.skipping("color-contrast")
        click_on "Remove API key"
      end

      wait_for { connection.reload.api_key }.to be_blank
      expect(connection.base_url).to eq(base_url)
    end

    it "disconnects without losing the configuration" do
      visit llm_connection_path
      expect(page).to have_field("Host URL")

      choose_action("llm-connection--disconnect")

      within_test_selector("llm-connection--disconnect-dialog") do
        expect(page).to be_axe_clean.skipping("color-contrast")
        click_on "Disconnect"
      end

      wait_for { Setting.llm_features_enabled? }.to be(false)
      expect(connection.api_key).to be_blank
      # The point of disconnecting rather than deleting.
      expect(connection.models.count).to eq(2)
    end

    describe "the health report" do
      before { mock_llm_chat_response(base_url) }

      it "runs the checks and renders the report accessibly" do
        visit llm_connection_path

        find_test_selector("llm-connection--run-health-checks").click

        wait_for { connection.health_reports.count }.to eq(1)

        find_test_selector("llm-connection--open-health-report").click

        expect(page).to have_current_path(llm_connection_health_status_report_path)
        expect(page).to have_text("Configuration")
        expect(page).to be_axe_clean.within("#content")
      end
    end
  end

  describe "the Feature configuration tab" do
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }

    before { mock_llm_embeddings_response(base_url) }

    it "offers the vector settings only for features that embed" do
      visit llm_feature_bindings_path

      expect(page).to have_test_selector("llm-settings--tabs")
      expect(page).to have_test_selector("llm-feature-binding--dimensions-semantic_search")
      expect(page).to have_no_test_selector("llm-feature-binding--dimensions-description_assistant")
      expect(page).to be_axe_clean.within("#content")
    end
  end
end

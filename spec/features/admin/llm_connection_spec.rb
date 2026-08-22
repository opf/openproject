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
  def choose_action(item)
    expect(page).to have_test_selector("llm-connection--actions")
    find_test_selector("llm-connection--actions").click
    expect(page).to have_test_selector(item)
    find_test_selector(item).click
  end

  context "when nothing is configured yet" do
    it "renders an accessible, empty settings page" do
      visit llm_connection_path

      expect(page).to have_field("Host URL")
      expect(page).to be_axe_clean.within("#content")
    end
  end

  context "with a configured connection" do
    let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:) }

    before { mock_llm_models_response(base_url) }

    it "renders the model list accessibly" do
      visit llm_connection_path

      expect(page).to have_test_selector("llm-model--toggle-#{connection.models.first.id}")
      expect(page).to be_axe_clean.within("#content")
    end

    it "hides a model from the feature pickers when it is switched off" do
      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")

      visit llm_connection_path
      find_test_selector("llm-model--toggle-#{llm_model.id}").click

      wait_for { llm_model.reload.deactivated_at }.not_to be_nil

      # The toggle acknowledges with JSON rather than re-rendering the row, so
      # the source label only catches up on the next load.
      visit llm_connection_path
      expect(page).to have_text("Hidden by administrator")
    end

    it "removes the stored API key" do
      visit llm_connection_path
      expect(page).to have_test_selector("llm-model--refresh-button")

      choose_action("llm-connection--delete-api-key")

      within_test_selector("llm-connection--delete-api-key-dialog") do
        expect(page).to be_axe_clean
        click_on "Remove API key"
      end

      wait_for { connection.reload.api_key }.to be_blank
      expect(connection.base_url).to eq(base_url)
    end

    it "disconnects without losing the configuration" do
      visit llm_connection_path
      expect(page).to have_test_selector("llm-model--refresh-button")

      choose_action("llm-connection--disconnect")

      within_test_selector("llm-connection--disconnect-dialog") do
        expect(page).to be_axe_clean
        click_on "Disconnect"
      end

      wait_for { connection.reload.enabled? }.to be(false)
      expect(connection.api_key).to be_blank
      # The point of disconnecting rather than deleting.
      expect(connection.models.count).to eq(2)
    end
  end
end

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

RSpec.describe "Choosing the form a type uses", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:other_type) { create(:type, name: "Feature") }

  let(:variant) { type.default_variant }
  let(:shared_form) { other_type.default_variant.form_configuration }

  before_all do
    other_type.default_variant.form_configuration.update!(name: "Standard form", description: "How the company works")
    other_type.default_variant.update!(attribute_groups: [["Planning", %w[assignee]]])
  end

  before { login_as admin }

  def choose_start(name)
    selected = "[data-test-selector='form_configuration-start-#{name}']:checked"

    retry_block do
      find_test_selector("form_configuration-start-#{name}").click
      raise "The #{name} option did not take the click" unless page.has_css?(selected, visible: :all, wait: 2)
    end
  end

  def open_create_dialog(start: "scratch")
    wait_for_turbo_stream { page.find_test_selector("form-create-new").click }

    within_dialog I18n.t("form_configurations.start.title") do
      yield if block_given?
      choose_start(start)
      click_on I18n.t(:button_continue)
    end
  end

  it "points the type at an existing form through the picker", :aggregate_failures do
    visit edit_type_form_configuration_path(type_id: type.id)

    within_test_selector("form_configuration-selector") { expect(page).to have_text("Bug form") }

    page.find_test_selector("form_configuration-selector").click
    within_test_selector("form_configuration-panel") { click_link "Standard form" }

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(variant.reload.form_configuration).to eq(shared_form)
    within_test_selector("form_configuration-selector") { expect(page).to have_text("Standard form") }
    expect(page).to have_text("Planning")
  end

  it "asks for the name before it creates, then opens the form's own page", :aggregate_failures do
    visit edit_type_form_configuration_path(type_id: type.id)

    open_create_dialog

    within_dialog I18n.t("form_configurations.form.new_title") do
      expect(page).to have_field("Form name", with: "Bug form (2)")

      fill_in "Form name", with: "Bug layout"
      click_on I18n.t(:button_create)
    end

    expect(page).to have_current_path(%r{/forms/\d+/edit})
    expect(page).to have_css(".PageHeader-title", text: "Bug layout")
    expect(variant.reload.form_configuration.name).to eq("Bug layout")
  end

  it "copies the groups of the form it was told to start from" do
    visit edit_type_form_configuration_path(type_id: type.id)

    open_create_dialog(start: "copy") do
      select_autocomplete(find_test_selector("form_configuration-copy-source"),
                          query: "Standard",
                          results_selector: "#form_configuration-dialog")
    end

    within_dialog(I18n.t("form_configurations.form.new_title")) { click_on I18n.t(:button_create) }

    expect(page).to have_current_path(%r{/forms/\d+/edit})
    expect(variant.reload.form_configuration.attribute_groups.map(&:key)).to eq(%w[Planning])
  end

  context "for a variant a project owns" do
    shared_let(:project) { create(:project, types: [type]) }
    shared_let(:owned) { create(:project_owned_type_variant, type:, project:, variant_name: "Local") }

    it "switches between forms but starts none" do
      visit edit_type_form_configuration_path(**owned.path_args)

      expect(page).to have_test_selector("form_configuration-selector")
      expect(page).to have_no_test_selector("form-create-new")
    end
  end
end

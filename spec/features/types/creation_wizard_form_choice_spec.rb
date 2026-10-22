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

RSpec.describe "Choosing a form in the type creation wizard", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:other_type) { create(:type, name: "Feature") }
  shared_let(:existing) { other_type.default_variant.form_configuration }

  before_all { existing.update!(name: "Standard form") }

  current_user { admin }

  def expect_chosen(name)
    expect(page).to have_css("[data-test-selector='form_configuration-choice-#{name}']:checked", visible: :all)
  end

  def create_type_through_wizard(name)
    visit types_path
    click_on I18n.t("activerecord.attributes.work_package.type")
    click_on I18n.t("types.creation_wizard.start.submit")
    fill_in Type.human_attribute_name(:name), with: name
    click_on I18n.t(:button_continue)

    expect(page).to have_current_path(/step=defaults/)
    Type.find_by!(name:)
  end

  def choose_option(name)
    wait_for_turbo_stream { find_test_selector("form_configuration-choice-#{name}").click }
  end

  def choose_form_start(name)
    selected = "[data-test-selector='form_configuration-start-#{name}']:checked"

    retry_block do
      find_test_selector("form_configuration-start-#{name}").click
      raise "The #{name} option did not take the click" unless page.has_css?(selected, visible: :all, wait: 2)
    end
  end

  def switch_to_existing(name)
    choose_option("existing")

    within_dialog I18n.t("form_configurations.change.title") do
      select_autocomplete(find_test_selector("change-form_configuration-select"),
                          query: name,
                          results_selector: "#change-form_configuration-dialog")
      click_on I18n.t(:button_save)
    end
  end

  it "opens the form step of a new type on the first existing form", :aggregate_failures do
    type = create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)

    expect(page).to have_current_path(/step=form_configuration/)
    expect_chosen("existing")
    expect(page).to have_test_selector("form_configuration-selector", text: "Standard form")
    expect(type.default_variant.reload.form_configuration).to eq(existing)
    expect(FormConfiguration.where(name: "Incident form")).to be_empty
  end

  it "switches a new type to a new form and back to an existing one", :aggregate_failures do
    type = create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)

    choose_option("new")
    within_dialog I18n.t("form_configurations.start.title") do
      choose_form_start("scratch")
      click_on I18n.t(:button_continue)
    end

    expect(page).to have_current_path(/started_form_configuration_id=#{type.default_variant.reload.form_configuration_id}/)
    expect(type.default_variant.form_configuration).not_to eq(existing)
    expect_chosen("new")
    expect(page).to have_no_test_selector("form_configuration-selector")

    switch_to_existing("Standard")

    expect(page).to have_current_path(/step=form_configuration/)
    expect(type.default_variant.reload.form_configuration).to eq(existing)
    expect_chosen("existing")
    expect(page).to have_test_selector("form_configuration-selector", text: "Standard form")
  end

  it "asks for the name and description of a new form on the way out", :aggregate_failures do
    type = create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)

    choose_option("new")
    within_dialog I18n.t("form_configurations.start.title") do
      choose_form_start("scratch")
      click_on I18n.t(:button_continue)
    end
    expect_chosen("new")

    click_on I18n.t(:button_continue)
    within_dialog I18n.t("form_configurations.form.edit_title") do
      expect(page).to have_field("Form name", with: "Incident form")
      fill_in "Form name", with: "Incident intake"
      fill_in "Description", with: "Used by the support team"
      click_on I18n.t(:button_save)
    end

    expect(page).to have_current_path(/step=project_attributes/)
    form = type.default_variant.reload.form_configuration
    expect(form).not_to eq(existing)
    expect(form.name).to eq("Incident intake")
    expect(form.description).to eq("Used by the support team")
  end

  it "keeps asking until the new form has a name" do
    create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)

    choose_option("new")
    within_dialog I18n.t("form_configurations.start.title") do
      choose_form_start("scratch")
      click_on I18n.t(:button_continue)
    end
    expect_chosen("new")

    click_on I18n.t(:button_continue)
    within_dialog I18n.t("form_configurations.form.edit_title") do
      fill_in "Form name", with: ""
      click_on I18n.t(:button_save)

      expect(page).to have_text(I18n.t("activerecord.errors.messages.blank"))
    end

    expect(page).to have_current_path(/step=form_configuration/)
  end

  it "moves on without asking while reusing an existing form" do
    create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)
    expect_chosen("existing")

    click_on I18n.t(:button_continue)

    expect(page).to have_current_path(/step=project_attributes/)
    expect(page).to have_no_css("dialog[open]")
    expect(existing.reload.name).to eq("Standard form")
  end

  it "opens the form step of a new variant on its type's form" do
    variant = WorkPackageTypes::CreateVariantService.new(user: admin, type: other_type)
                                                    .call(variant_name: "Hardware").result

    visit type_variant_creation_wizard_path(type_id: other_type.id, variant_id: variant.id, step: :form_configuration)

    expect_chosen("existing")
    within_test_selector("form_configuration-selector") do
      expect(page).to have_text("Standard form")
      expect(page).to have_text(I18n.t("form_configurations.selector.same_as_type"))
    end
  end

  describe "with a default form" do
    shared_let(:default_form) { create(:form_configuration, name: "Company form", is_default: true) }

    it "opens the form step of a new type on the default form", :aggregate_failures do
      type = create_type_through_wizard("Incident")
      click_on I18n.t(:button_continue)

      expect(page).to have_current_path(/step=form_configuration/)
      expect_chosen("existing")
      expect(page).to have_test_selector("form_configuration-selector",
                                         text: "Company form #{I18n.t('form_configurations.selector.default')}")
      expect(type.default_variant.reload.form_configuration).to eq(default_form)
      expect(FormConfiguration.where(name: "Incident form")).to be_empty
    end

    it "marks the default form in the list of existing forms" do
      create_type_through_wizard("Incident")
      click_on I18n.t(:button_continue)

      find_test_selector("form_configuration-selector").click

      within_test_selector("form_configuration-panel") do
        expect(page).to have_css(".ActionListItem", text: "Company form") { |item|
          item.has_css?(".ActionListItem-visual--trailing", text: I18n.t("form_configurations.selector.default"))
        }
        expect(page).to have_css(".ActionListItem", text: "Standard form") { |item|
          item.has_no_css?(".ActionListItem-visual--trailing")
        }
      end
    end

    it "still opens the form step of a new variant on its type's form" do
      variant = WorkPackageTypes::CreateVariantService.new(user: admin, type: other_type)
                                                      .call(variant_name: "Hardware").result

      visit type_variant_creation_wizard_path(type_id: other_type.id, variant_id: variant.id, step: :form_configuration)

      expect_chosen("existing")
      expect(page).to have_test_selector("form_configuration-selector", text: "Standard form")
      expect(page).to have_no_test_selector("form_configuration-selector",
                                            text: I18n.t("form_configurations.selector.default"))
      expect(variant.reload.form_configuration).to eq(existing)
    end
  end
end

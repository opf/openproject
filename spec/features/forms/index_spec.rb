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

RSpec.describe "Forms index", :js do
  shared_let(:admin) { create(:admin) }

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:phase) { create(:type, name: "Phase") }

  shared_let(:hardware_form) { create(:form_configuration, name: "Hardware form") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware", form_configuration: hardware_form) }

  shared_let(:on_bug) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:on_hardware) { create(:project, name: "Foundry", types: [hardware]) }

  before_all do
    bug.default_variant.form_configuration.update!(name: "Bug form", description: "The agreed one")
    phase.default_variant.form_configuration.update!(name: "Phase form")

    orphan = task.default_variant.form_configuration
    task.default_variant.update!(form_configuration: bug.default_variant.form_configuration)
    orphan.reload.destroy!
  end

  current_user { admin }

  def all_forms = ["Bug form", "Hardware form", "Phase form"]

  def results = "#form_configurations-index-results-component"

  def row_for(name)
    page.find(".Box-row") { |row| row.has_css?(".name a", text: name, exact_text: true) }
  end

  def expect_listed(*names)
    names.each { |name| expect(page).to have_css("#{results} .name a", text: name, exact_text: true) }

    (all_forms - names).each do |absent|
      expect(page).to have_no_css("#{results} .name a", text: absent, exact_text: true)
    end
  end

  it "is reachable from the administration menu" do
    visit admin_settings_work_packages_general_path

    within("#menu-sidebar") { click_link_or_button I18n.t(:label_form_configuration_plural) }

    expect(page).to have_current_path(form_configurations_path)
    expect(page).to have_css(".PageHeader-title", text: I18n.t(:label_form_configuration_plural))
    within("#menu-sidebar") do
      expect(page).to have_css(".selected", text: I18n.t(:label_form_configuration_plural))
    end
  end

  it "gives one row per form, counting what each one reaches" do
    visit form_configurations_path

    expect_listed(*all_forms)

    within(row_for("Bug form")) do
      expect(page).to have_text("The agreed one")
      expect(page).to have_css(".types_and_variants", text: "2 types")
      expect(page).to have_css(".projects", text: "1 project")
      expect(page).to have_no_css(".roles")
    end

    within(row_for("Hardware form")) do
      expect(page).to have_css(".types_and_variants", text: "1 type (including 1 variant)")
      expect(page).to have_css(".projects", text: "1 project")
    end
  end

  it "narrows the list as a name is typed" do
    visit form_configurations_path

    within_test_selector("form_configurations-sub-header") do
      click_button accessible_name: I18n.t("form_configurations.index.filters.name"), exact: true
      fill_in Queries::FormConfigurations::Filters::NameFilter.key.to_s, with: "Hardw"
    end

    expect_listed("Hardware form")
  end

  it "renames a form from its row" do
    visit form_configurations_path

    within(row_for("Phase form")) do
      click_button accessible_name: I18n.t("form_configurations.index.actions.menu", name: "Phase form")
    end
    find_test_selector("form_configuration-rename-action").click

    within_dialog I18n.t("form_configurations.form.edit_title") do
      fill_in I18n.t("form_configurations.form.name.label"), with: "Phase layout"
      click_link_or_button I18n.t(:button_save)
    end

    expect(page).to have_css(".PageHeader-title", text: "Phase layout")
    expect(phase.default_variant.form_configuration.reload.name).to eq("Phase layout")
  end

  describe "the default form" do
    let!(:company_form) { create(:form_configuration, name: "Company form", is_default: true) }

    def open_row_menu(name)
      within(row_for(name)) do
        click_button accessible_name: I18n.t("form_configurations.index.actions.menu", name:)
      end
    end

    it "is listed first, before the forms sorted by name" do
      visit form_configurations_path

      expect_listed(*all_forms)
      expect(page.all("#{results} .name a").map(&:text)).to eq(["Company form", *all_forms])
    end

    it "carries a label in its row and offers no deletion there" do
      visit form_configurations_path

      within(row_for("Company form")) { expect(page).to have_test_selector("form_configuration-default-label") }
      within(row_for("Phase form")) { expect(page).to have_no_test_selector("form_configuration-default-label") }

      open_row_menu("Company form")
      expect(page).to have_no_test_selector("form_configuration-mark-default-action")
      expect(page).to have_no_css(".ActionListItem", text: I18n.t(:button_delete))
    end

    it "moves to another form marked from its row" do
      visit form_configurations_path

      open_row_menu("Phase form")
      find_test_selector("form_configuration-mark-default-action").click

      expect_flash(message: I18n.t("form_configurations.default.marked", name: "Phase form"))
      within(row_for("Phase form")) { expect(page).to have_test_selector("form_configuration-default-label") }
      within(row_for("Company form")) { expect(page).to have_no_test_selector("form_configuration-default-label") }
      expect(FormConfiguration.default_form).to eq(phase.default_variant.form_configuration)
    end

    it "moves to the form marked on its page, which then offers no deletion" do
      visit edit_form_configuration_path(phase.default_variant.form_configuration)

      find_test_selector("form_configuration-actions").click
      find_test_selector("form_configuration-mark-default-action").click

      expect_flash(message: I18n.t("form_configurations.default.marked", name: "Phase form"))
      expect(page).to have_current_path(edit_form_configuration_path(phase.default_variant.form_configuration))
      expect(page).to have_test_selector("form_configuration-default-label")

      find_test_selector("form_configuration-actions").click
      expect(page).to have_test_selector("form_configuration-edit-action")
      expect(page).to have_no_test_selector("form_configuration-mark-default-action")
      expect(page).to have_no_test_selector("form_configuration-delete-action")
      expect(company_form.reload).not_to be_is_default
    end
  end

  describe "a type's form tab" do
    it "shows the form read-only and leads to its page for editing", :aggregate_failures do
      visit edit_type_form_configuration_path(type_id: bug.id)

      within_test_selector("form-configuration-read-only") do
        click_link_or_button I18n.t("form_configurations.tab.read_only.edit_action")
      end

      expect(page).to have_current_path(edit_form_configuration_path(bug.default_variant.form_configuration))
      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end

  describe "the form page" do
    it "lists the types and variants using the form" do
      visit edit_form_configuration_path(bug.default_variant.form_configuration)

      expect(page).to have_css(".PageHeader-title", text: "Bug form")
      within_test_selector("form_configuration-usage-banner") do
        expect(page).to have_text(I18n.t("form_configurations.usage.used_by_types", count: 2))
      end
    end

    it "refuses to delete a form a type still uses" do
      visit edit_form_configuration_path(bug.default_variant.form_configuration)

      find_test_selector("form_configuration-actions").click
      accept_confirm { find_test_selector("form_configuration-delete-action").click }

      expect(page).to have_current_path(form_configurations_path)
      expect(FormConfiguration).to exist(bug.default_variant.form_configuration.id)
    end

    it "deletes a form nothing uses" do
      spare = create(:form_configuration, name: "Spare form")

      visit edit_form_configuration_path(spare)

      find_test_selector("form_configuration-actions").click
      accept_confirm { find_test_selector("form_configuration-delete-action").click }

      expect(page).to have_current_path(form_configurations_path)
      expect(page).to have_text(I18n.t(:notice_successful_delete))
      expect(FormConfiguration).not_to exist(spare.id)
    end
  end
end

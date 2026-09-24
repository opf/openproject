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

RSpec.describe "Type creation wizard", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:project_role) { create(:project_role) }

  before { login_as(admin) }

  # There is no flash message; a completed step's sidebar marker turning into the check is what
  # tells us its submission was accepted. Asserting the completed step's own state (rather than
  # the next step's content) keeps the specs correct if the order changes.
  def expect_step_saved(step)
    within_test_selector("wizard-step-#{step}") do
      expect(page).to have_css(".octicon-check-circle-fill")
    end
  end

  def start_wizard
    visit types_path
    click_on I18n.t("activerecord.attributes.work_package.type")
    click_on I18n.t("types.creation_wizard.start.submit")
  end

  def complete_details_step(name)
    fill_in Type.human_attribute_name(:name), with: name
    click_on I18n.t(:button_continue)

    expect_step_saved(:details)

    Type.find_by!(name:)
  end

  it "guides the admin through creating a type" do
    start_wizard

    expect(page).to have_text(I18n.t("types.creation_wizard.create_type"))
    expect(page).to have_field(Type.human_attribute_name(:is_milestone), disabled: false)

    type = complete_details_step("Incident")

    expect(page).to have_text(I18n.t("types.edit.defaults.description.label"))
    click_on I18n.t(:button_continue)
    expect_step_saved(:defaults)

    expect(page).to have_heading("Form")
    click_on I18n.t(:button_continue)
    expect_step_saved(:form_configuration)

    expect(page).to have_heading("Project attributes")
    click_on I18n.t(:button_continue)
    expect_step_saved(:project_attributes)

    expect(page).to have_heading("Workflows")
    expect(page).to have_text(I18n.t("admin.workflows.tabs.always"))
    click_on I18n.t(:button_continue)
    expect_step_saved(:workflows)

    click_on I18n.t(:button_continue)
    expect_step_saved(:projects)

    expect(page).to have_heading("PDF generation")
    click_on I18n.t("types.creation_wizard.finish")

    expect_flash(message: I18n.t("types.creation_wizard.success"))
    expect(page).to have_current_path(types_path)
    expect(type.reload.name).to eq("Incident")
  end

  it "creates a type with the core settings editable" do
    start_wizard

    expect(page).to have_text(I18n.t("types.creation_wizard.create_type"))
    expect(page).to have_field(Type.human_attribute_name(:is_milestone), disabled: false)

    fill_in Type.human_attribute_name(:name), with: "Incident"
    check Type.human_attribute_name(:is_milestone)
    click_on I18n.t(:button_continue)

    expect_step_saved(:details)
    expect(Type.find_by(name: "Incident")).to have_attributes(is_milestone: true)
  end

  it "persists the defaults step through the wizard footer" do
    start_wizard
    type = complete_details_step("Critical")

    visit type_creation_wizard_path(type, step: :defaults)

    Components::WysiwygEditor.new.set_markdown("Reproduce the bug first")
    click_on I18n.t(:button_continue)

    expect_step_saved(:defaults)
    expect(type.default_variant.reload.default_work_package_description).to eq("Reproduce the bug first")
  end

  describe "adding a variant" do
    shared_let(:bug_type) { create(:type, name: "Bug") }

    def start_variant_wizard
      visit type_variants_path(type_id: bug_type.id)
      find_test_selector("add-type-variant").click
      click_on I18n.t("types.creation_wizard.start.submit")
    end

    it "keeps the wizard on the variant when a sidebar step is clicked" do
      start_variant_wizard

      fill_in TypeVariant.human_attribute_name(:variant_name), with: "Hardware"
      click_on I18n.t(:button_continue)

      expect_step_saved(:details)
      variant = bug_type.variants.reload.find_by!(variant_name: "Hardware")

      within_test_selector("wizard-step-details") { click_on I18n.t("types.creation_wizard.steps.details") }

      expect(page).to have_text(I18n.t("types.creation_wizard.add_variant", name: bug_type.name))
      expect(page).to have_field(TypeVariant.human_attribute_name(:variant_name), with: "Hardware")
      expect(page).to have_current_path(
        type_creation_wizard_path(type_id: bug_type.id, variant_id: variant.id, step: :details,
                                  back_url: type_variants_path(type_id: bug_type.id))
      )
    end

    it "keeps the wizard on the variant when going back through the footer" do
      start_variant_wizard

      fill_in TypeVariant.human_attribute_name(:variant_name), with: "Hardware"
      click_on I18n.t(:button_continue)

      expect_step_saved(:details)
      click_on I18n.t(:button_back)

      expect(page).to have_text(I18n.t("types.creation_wizard.add_variant", name: bug_type.name))
      expect(page).to have_field(TypeVariant.human_attribute_name(:variant_name), with: "Hardware")
    end
  end
end

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

RSpec.describe "Variant creation wizard", :js, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug", color: create(:color)) }
  shared_let(:project_role) { create(:project_role) }

  before { login_as(admin) }

  def start_wizard
    visit types_path

    # The type's group is collapsed by default, hiding its "Add variant" footer link.
    find("[role='button'][aria-expanded='false']", text: bug_type.name).click
    click_on I18n.t("types.index.add_variant", name: bug_type.name)
  end

  def inherited_caption
    ActionController::Base.helpers.strip_tags(
      I18n.t("types.creation_wizard.fields.inherited_from_parent_html", parent: bug_type.name)
    )
  end

  # There is no flash message; a step's sidebar marker resolving to its reuse-mode icon
  # is what tells us its submission was accepted. A completed step shows the chain icon
  # when its aspect is Linked and the pencil when Independent. Asserting the completed step's own
  # state (rather than the next step's content) keeps the specs correct if the order changes.
  def expect_step_saved(step, linked: true)
    within_test_selector("wizard-step-#{step}") do
      expect(page).to have_css(linked ? ".octicon-link" : ".octicon-pencil")
    end
  end

  def complete_details_step(name)
    fill_in Type.human_attribute_name(:name), with: name
    click_on I18n.t(:button_continue)

    expect_step_saved(:details, linked: false)

    bug_type.children.find_by(name:).tap { |variant| expect(variant).to be_present }
  end

  it "guides the admin through creating a variant with defaults" do
    start_wizard

    # Step 1 - Details: the core settings are inherited from the parent and shown read-only.
    expect(page).to have_text(inherited_caption, count: 3)
    expect(page).to have_field(Type.human_attribute_name(:is_milestone), disabled: true)
    expect(page).to have_field(Type.human_attribute_name(:is_in_roadmap), disabled: true)
    expect(page).to have_css(".colors-autocomplete .ng-select-disabled")

    variant = complete_details_step("Critical")

    # Step 2 - Defaults: linked to the parent on creation, so it renders read-only and
    # the footer, not a Save button, drives submission.
    expect(page).to have_text(I18n.t("types.edit.defaults.description.label"))
    expect(page).to have_no_button(I18n.t(:button_save))
    click_on I18n.t(:button_continue)

    # Step 3 - Form configuration: linked to the parent on creation, so it renders read-only.
    expect(page).to have_heading("Form configuration") # the main content, not the sidebar entry
    expect(page).to have_text("Linked mode")
    click_on I18n.t(:button_continue)
    expect_step_saved(:form_configuration)

    # Step 4 - Project attributes: linked to the parent on creation, so it renders read-only.
    expect(page).to have_heading("Project attributes") # the main content, not the sidebar entry
    expect(page).to have_text("Linked mode")
    click_on I18n.t(:button_continue)
    expect_step_saved(:project_attributes)

    # Step 5 - Workflow: the matrix has no Save of its own, Continue persists it.
    expect(page).to have_text("Linked mode")
    expect(page).to have_no_button "Save"
    click_on I18n.t(:button_continue)
    expect_step_saved(:workflows)

    # Step 6 - Projects
    click_on I18n.t(:button_continue)
    expect_step_saved(:projects, linked: false)

    # Step 7 - PDF generation: linked to the parent on creation, so it renders read-only.
    expect(page).to have_heading("PDF generation") # the main content, not the sidebar entry
    expect(page).to have_text("Linked mode")
    click_on I18n.t("types.creation_wizard.finish")

    expect_flash(message: "Variant created successfully.")
    expect(page).to have_current_path(types_path)
    expect(variant.reload.parent).to eq(bug_type)
  end

  it "creates a root type with the core settings editable" do
    visit types_path
    click_on I18n.t("activerecord.attributes.work_package.type")

    expect(page).to have_text(I18n.t("types.creation_wizard.create_type"))
    expect(page).to have_no_text(inherited_caption)
    expect(page).to have_field(Type.human_attribute_name(:is_milestone), disabled: false)

    fill_in Type.human_attribute_name(:name), with: "Incident"
    check Type.human_attribute_name(:is_milestone)
    click_on I18n.t(:button_continue)

    expect_step_saved(:details, linked: false)
    expect(Type.find_by(name: "Incident")).to have_attributes(parent: nil, is_milestone: true)
  end

  it "persists the defaults step through the wizard footer once the aspect is independent" do
    start_wizard
    variant = complete_details_step("Critical")

    # Independent mode is what makes the fields editable; linked mode renders read-only.
    variant.configuration_links.where(aspect: Type::ConfigurationLink::DEFAULTS).destroy_all
    visit type_creation_wizard_path(variant, step: :defaults)

    Components::WysiwygEditor.new.set_markdown("Reproduce the bug first")
    click_on I18n.t(:button_continue)

    expect_step_saved(:defaults, linked: false)
    expect(variant.reload.description).to eq("Reproduce the bug first")
  end

  it "links the aspects a variant inherits from its parent on creation" do
    start_wizard
    variant = complete_details_step("Critical")

    # Reuse mode is no longer chosen in the wizard: a new variant simply defaults
    # to Linked-to-parent for the aspects it inherits (see Type::ConfigurationLinkable).
    Type::ConfigurationLink::ASPECTS.each do |aspect|
      expect(variant.source_for(aspect)).to eq(bug_type)
    end
  end
end

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

RSpec.describe "Sub-type creation wizard", :js, with_flag: { subtypes: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }
  shared_let(:epic_type) { create(:type, name: "Epic") }

  let(:independent_label) { I18n.t("types.edit.configuration_link.independent.label") }
  let(:linked_label) { I18n.t("types.edit.configuration_link.linked.label") }
  let(:source_label) { I18n.t("types.edit.configuration_link.source.label") }

  before { login_as(admin) }

  def start_wizard
    visit types_path

    # The type's group is collapsed by default, hiding its "Add sub-type" footer link.
    find("[role='button'][aria-expanded='false']", text: bug_type.name).click
    click_on I18n.t("types.index.add_subtype", name: bug_type.name)
  end

  def inherited_caption
    ActionController::Base.helpers.strip_tags(
      I18n.t("types.creation_wizard.fields.inherited_from_parent_html", parent: bug_type.name)
    )
  end

  def complete_details_step(name)
    fill_in Type.human_attribute_name(:name), with: name
    click_on I18n.t(:button_continue)

    bug_type.children.find_by(name:).tap { |subtype| expect(subtype).to be_present }
  end

  # Reuse mode is per-aspect, so each step carries its own selector.
  def choose_linked_source(source)
    choose linked_label
    select source.name, from: source_label
  end

  it "guides the admin through creating a sub-type with defaults" do
    start_wizard

    # Step 1 - Details: identity only, so no reuse mode to choose. The core settings
    # are inherited from the parent and shown read-only.
    expect(page).to have_no_text(independent_label)
    expect(page).to have_text(inherited_caption, count: 3)
    expect(page).to have_field(Type.human_attribute_name(:is_milestone), disabled: true)
    expect(page).to have_field(Type.human_attribute_name(:is_in_roadmap), disabled: true)
    expect(page).to have_css(".colors-autocomplete .ng-select-disabled")

    subtype = complete_details_step("Critical")

    # Step 2 - Form configuration: every step from here offers the reuse mode selector.
    expect(page).to have_text(independent_label)
    expect(page).to have_text(linked_label)

    click_on I18n.t(:button_continue) # -> Workflows
    click_on I18n.t(:button_continue) # -> Automations
    click_on I18n.t(:button_continue) # -> Projects
    click_on I18n.t(:button_continue) # -> PDF generation
    click_on I18n.t("types.creation_wizard.finish")

    expect(page).to have_current_path(types_path)
    expect(subtype.reload.parent).to eq(bug_type)
  end

  describe "reuse mode" do
    it "defaults the aspects a sub-type does not inherit yet to Independent" do
      start_wizard
      subtype = complete_details_step("Critical")

      # PDF export defaults to Linked-to-parent on creation, so it is asserted separately.
      independent_steps = WorkPackageTypes::Wizard::Steps::STEP_ASPECTS.except(:pdf)

      independent_steps.each_value do |aspect|
        expect(page).to have_checked_field(independent_label)
        expect(subtype).not_to be_linked(aspect)

        click_on I18n.t(:button_continue)
      end
    end

    it "keeps the PDF aspect a sub-type inherits from its parent Linked" do
      start_wizard
      subtype = complete_details_step("Critical")

      visit type_creation_wizard_path(subtype, step: :pdf)

      expect(page).to have_checked_field(linked_label)
      expect(page).to have_select(source_label, selected: bug_type.name)
      expect(subtype.source_for(Type::ConfigurationLink::PDF_EXPORT)).to eq(bug_type)
    end

    it "preselects the parent as the source rather than the first available type" do
      start_wizard
      complete_details_step("Critical")

      # The picker is revealed only once Linked is chosen.
      choose linked_label

      expect(page).to have_select(source_label, selected: bug_type.name)
    end

    it "links only the aspect whose step was set to Linked" do
      start_wizard
      subtype = complete_details_step("Critical")

      # Step 2 - Form configuration: link it to Epic rather than the default parent.
      choose_linked_source(epic_type)
      click_on I18n.t(:button_continue) # -> Workflows

      expect(subtype.source_for(Type::ConfigurationLink::FORM_CONFIGURATION)).to eq(epic_type)

      # The remaining steps keep their default, so they stay Independent.
      click_on I18n.t(:button_continue) # -> Automations
      click_on I18n.t(:button_continue) # -> Projects
      click_on I18n.t(:button_continue) # -> PDF generation
      click_on I18n.t("types.creation_wizard.finish")

      expect(subtype.reload).to be_linked(Type::ConfigurationLink::FORM_CONFIGURATION)
      expect(subtype).not_to be_linked(Type::ConfigurationLink::WORKFLOWS)
      expect(subtype).not_to be_linked(Type::ConfigurationLink::AUTOMATIONS)
      expect(subtype).not_to be_linked(Type::ConfigurationLink::PROJECTS)
    end

    it "links an aspect to the parent when Linked is chosen with the default source" do
      start_wizard
      subtype = complete_details_step("Critical")

      click_on I18n.t(:button_continue) # -> Workflows

      choose linked_label
      click_on I18n.t(:button_continue) # -> Automations

      expect(subtype.source_for(Type::ConfigurationLink::WORKFLOWS)).to eq(bug_type)
    end
  end
end

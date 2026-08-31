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

RSpec.describe "Work package variants index", :js, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }
  shared_let(:feature_type) { create(:type, name: "Feature") }
  shared_let(:zeta_variant) { create(:type_variant, type: bug_type, variant_name: "Zeta variant") }
  shared_let(:alfa_variant) { create(:type_variant, type: bug_type, variant_name: "Alpha variant") }

  before { login_as(admin) }

  it "makes only types draggable via a drag handle" do
    visit types_path

    expect(page).to have_text(bug_type.name)
    expect(page).to have_text(feature_type.name)

    expect(page).to have_css("[data-draggable-id='#{bug_type.id}'] .DragHandle", visible: :all)
    expect(page).to have_css("[data-draggable-id='#{feature_type.id}'] .DragHandle", visible: :all)

    variant_row = page.find(".Box-row", text: alfa_variant.variant_name, visible: :all)
    expect(variant_row).to have_no_css(".DragHandle", visible: :all)
  end

  it "links a type's header to its settings page" do
    visit types_path

    expect(page).to have_link(bug_type.name, href: edit_type_details_path(type_id: bug_type.id))
  end

  it "links a variant to its settings page, as a type's header links to its own" do
    visit types_path(expand: bug_type.id)

    expect(page).to have_link(
      alfa_variant.variant_name,
      href: edit_type_details_path(type_id: bug_type.id, variant_id: alfa_variant.id)
    )
  end

  it "counts a type's named variants in a badge on its header" do
    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      expect(page).to have_css(".Counter", text: "2")
    end

    # Nothing to count, so nothing to show.
    within("[data-draggable-id='#{feature_type.id}'] .Box-header") do
      expect(page).to have_no_css(".Counter")
    end
  end

  it "badges the type that is activated in new projects" do
    feature_type.default_variant.update!(enabled_in_new_projects: true)

    visit types_path

    within("[data-draggable-id='#{feature_type.id}'] .Box-header") do
      expect(page).to have_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"))
    end

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      expect(page).to have_no_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"))
    end
  end

  it "offers configure, move and delete on a type" do
    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      expect(page).to have_link(I18n.t(:button_configure))
      expect(page).to have_button(I18n.t(:button_move))
      expect(page).to have_button(I18n.t(:button_delete))
    end
  end

  it "offers configure and delete on a variant" do
    visit types_path(expand: bug_type.id)

    within(".Box-row", text: alfa_variant.variant_name) do
      find("action-menu > button").click

      expect(page).to have_link(
        I18n.t(:button_configure),
        href: edit_type_details_path(type_id: bug_type.id, variant_id: alfa_variant.id)
      )
      expect(page).to have_button(I18n.t(:button_delete))
    end
  end

  it "expands the group named by the expand param" do
    visit types_path(expand: bug_type.id)

    expect(page).to have_link(alfa_variant.variant_name)
    expect(page).to have_link(zeta_variant.variant_name)
  end

  it "lists a group's variants alphabetically" do
    visit types_path

    expect(page).to have_link(alfa_variant.variant_name, visible: :all)
    expect(page).to have_link(zeta_variant.variant_name, visible: :all)
    expect(page.body.index(alfa_variant.variant_name)).to be < page.body.index(zeta_variant.variant_name)
  end

  it "adds a variant to a type from the group's add-variant row" do
    visit types_path(expand: bug_type.id)

    within("[data-draggable-id='#{bug_type.id}']") do
      click_on I18n.t("types.index.add_variant", name: bug_type.name)
    end

    expect(page).to have_text(I18n.t("types.creation_wizard.add_variant", name: bug_type.name))

    fill_in TypeVariant.human_attribute_name(:variant_name), with: "Hardware"
    click_on I18n.t(:button_continue)

    expect(bug_type.reload.variants.non_default_variants.pluck(:variant_name))
      .to contain_exactly("Alpha variant", "Zeta variant", "Hardware")
  end

  it "returns to the index when the add-variant wizard is cancelled" do
    visit types_path(expand: bug_type.id)

    within("[data-draggable-id='#{bug_type.id}']") do
      click_on I18n.t("types.index.add_variant", name: bug_type.name)
    end

    expect(page).to have_text(I18n.t("types.creation_wizard.add_variant", name: bug_type.name))

    click_on I18n.t(:button_cancel), match: :first

    expect(page).to have_current_path(types_path)
  end

  it "duplicates a type from its action menu" do
    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      click_on I18n.t(:button_duplicate)
    end

    expect(page).to have_text(I18n.t("types.index.duplicate_notice", name: bug_type.name))
    expect(page).to have_text(I18n.t("types.index.duplicate_name", name: bug_type.name))
    expect(Type.exists?(name: I18n.t("types.index.duplicate_name", name: bug_type.name))).to be(true)
  end

  it "reorders types via drag and drop", :selenium do
    visit types_path

    expect(bug_type.position).to be < feature_type.position

    drag_handle = page.find("[data-draggable-id='#{feature_type.id}'] .DragHandle")
    target = page.find("[data-draggable-id='#{bug_type.id}']")

    drag_n_drop_element(from: drag_handle, to: target)

    wait_for { feature_type.reload.position }.to be < bug_type.reload.position
  end

  it "reorders a type via the async 'Move' submenu" do
    visit types_path

    expect(bug_type.position).to be < feature_type.position

    within("[data-draggable-id='#{feature_type.id}'] .Box-header") do
      find("action-menu > button").click
      click_on I18n.t(:button_move)
      click_on I18n.t(:label_sort_highest)
    end

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(feature_type.reload.position).to be < bug_type.reload.position
  end

  describe "deleting a variant that projects still apply" do
    shared_let(:project) { create(:project, types: [bug_type]) }

    before { project.project_types.find_by(type: bug_type).update!(variant: zeta_variant) }

    it "migrates the applying projects to a chosen sibling, then deletes it" do
      visit types_path(expand: bug_type.id)

      within(".Box-row", text: zeta_variant.variant_name) do
        find("action-menu > button").click
        click_on I18n.t(:button_delete)
      end

      within("##{WorkPackageTypes::Types::DeletionDialogComponent::DIALOG_ID}") do
        select alfa_variant.composite_name, from: I18n.t("projects.settings.types.switch.target_label")
        click_on I18n.t(:button_delete)
      end

      expect(page).to have_text(I18n.t(:notice_successful_delete))
      expect { zeta_variant.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(project.project_types.find_by(type: bug_type).variant).to eq(alfa_variant)
    end
  end
end

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
  shared_let(:zeta_variant) { create(:type, name: "Zeta variant", parent: bug_type) }
  shared_let(:alfa_variant) { create(:type, name: "Alpha variant", parent: bug_type) }

  before { login_as(admin) }

  it "makes only root types draggable via a drag handle" do
    visit types_path

    expect(page).to have_text(bug_type.name)
    expect(page).to have_text(feature_type.name)

    expect(page).to have_css("[data-draggable-id='#{bug_type.id}'] .DragHandle", visible: :all)
    expect(page).to have_css("[data-draggable-id='#{feature_type.id}'] .DragHandle", visible: :all)

    variant_row = page.find(".Box-row", text: alfa_variant.own_name, visible: :all)
    expect(variant_row).to have_no_css(".DragHandle", visible: :all)
  end

  it "links a root type's header to its settings page" do
    visit types_path

    expect(page).to have_link(bug_type.name, href: edit_type_details_path(type_id: bug_type.id))
  end

  it "offers 'Move' only on roots, while both roots and variants can be configured and deleted" do
    visit types_path(expand: bug_type.id)

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      expect(page).to have_link(I18n.t(:button_configure))
      expect(page).to have_button(I18n.t(:button_move))
      expect(page).to have_button(I18n.t(:button_delete))
    end
    find("body").send_keys :escape

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      expect(page).to have_link(I18n.t(:button_configure))
      expect(page).to have_button(I18n.t(:button_delete))
      expect(page).to have_no_button(I18n.t(:button_move))
    end
  end

  it "badges the type and the variant that are marked as default" do
    feature_type.update!(is_default: true)
    alfa_variant.update!(is_default: true)

    visit types_path

    within("[data-draggable-id='#{feature_type.id}'] .Box-header") do
      expect(page).to have_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"))
    end

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      expect(page).to have_no_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"))
    end

    within(".Box-row", text: alfa_variant.own_name, visible: :all) do
      expect(page).to have_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"), visible: :all)
    end

    within(".Box-row", text: zeta_variant.own_name, visible: :all) do
      expect(page).to have_no_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"), visible: :all)
    end
  end

  it "names the default variant in the collapsed header of its group" do
    alfa_variant.update!(is_default: true)

    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      expect(page).to have_css(
        ".Label",
        text: I18n.t("types.index.variant_enabled_in_new_projects", name: alfa_variant.own_name)
      )
    end

    within("[data-draggable-id='#{feature_type.id}'] .Box-header") do
      expect(page).to have_no_css(".Label")
    end
  end

  it "shows the type's own label rather than a variant's when the root is the default" do
    bug_type.update!(is_default: true)

    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      expect(page).to have_css(".Label", text: I18n.t("types.index.enabled_in_new_projects"))
    end
  end

  it "offers activating on every type and variant, and deactivating on the current default" do
    alfa_variant.update!(is_default: true)

    visit types_path(expand: bug_type.id)

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      expect(page).to have_button(I18n.t("types.index.make_default"))
      expect(page).to have_no_button(I18n.t("types.index.remove_default"))
    end
    find("body").send_keys :escape

    within(".Box-row", text: zeta_variant.own_name) do
      find("action-menu > button").click
      expect(page).to have_button(I18n.t("types.index.make_default"))
      expect(page).to have_no_button(I18n.t("types.index.remove_default"))
    end
    find("body").send_keys :escape

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      expect(page).to have_button(I18n.t("types.index.remove_default"))
      expect(page).to have_no_button(I18n.t("types.index.make_default"))
    end
  end

  it "removes the default from the chosen variant" do
    alfa_variant.update!(is_default: true)

    visit types_path

    find(".Box-header", text: bug_type.name).click

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      click_on I18n.t("types.index.remove_default")
    end

    expect(page).to have_text(
      I18n.t("types.index.remove_default_notice", name: alfa_variant.own_name)
    )
    expect(alfa_variant.reload).not_to be_is_default
  end

  it "moves the default to the chosen variant" do
    bug_type.update!(is_default: true)

    visit types_path

    find(".Box-header", text: bug_type.name).click

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      click_on I18n.t("types.index.make_default")
    end

    expect(page).to have_text(
      I18n.t("types.index.make_default_notice", name: alfa_variant.own_name)
    )
    expect(alfa_variant.reload).to be_is_default
    expect(bug_type.reload).not_to be_is_default
  end

  it "keeps the affected variant's group expanded after setting it as default" do
    visit types_path

    find(".Box-header", text: bug_type.name).click

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      click_on I18n.t("types.index.make_default")
    end

    expect(page).to have_text(I18n.t("types.index.make_default_notice", name: alfa_variant.own_name))
    expect(page).to have_link(alfa_variant.own_name)
    expect(page).to have_link(zeta_variant.own_name)
  end

  it "leaves the groups collapsed after setting a root type as default" do
    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      click_on I18n.t("types.index.make_default")
    end

    expect(page).to have_text(I18n.t("types.index.make_default_notice", name: bug_type.own_name))
    expect(page).to have_no_link(alfa_variant.own_name)
  end

  it "expands the group named by the expand param" do
    visit types_path(expand: bug_type.id)

    expect(page).to have_link(alfa_variant.own_name)
    expect(page).to have_link(zeta_variant.own_name)
  end

  it "lists a group's variants alphabetically" do
    visit types_path

    expect(page).to have_link(alfa_variant.own_name, visible: :all)
    expect(page).to have_link(zeta_variant.own_name, visible: :all)
    expect(page.body.index(alfa_variant.own_name)).to be < page.body.index(zeta_variant.own_name)
  end

  it "offers 'Add variant' only on roots, linking to the creation wizard for that root" do
    visit types_path(expand: bug_type.id)

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      expect(page).to have_link(
        I18n.t("types.index.add_variant_action"),
        href: new_creation_wizard_types_path(parent_id: bug_type.id)
      )
    end
    find("body").send_keys :escape

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      expect(page).to have_no_link(I18n.t("types.index.add_variant_action"))
    end
  end

  it "duplicates a root type from its action menu" do
    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      click_on I18n.t(:button_duplicate)
    end

    expect(page).to have_text(I18n.t("types.index.duplicate_notice", name: bug_type.own_name))
    expect(page).to have_text(I18n.t("types.index.duplicate_name", name: bug_type.own_name))
    expect(Type.exists?(name: I18n.t("types.index.duplicate_name", name: bug_type.own_name))).to be(true)
  end

  it "offers 'Duplicate' on both roots and variants" do
    visit types_path(expand: bug_type.id)

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      find("action-menu > button").click
      expect(page).to have_button(I18n.t(:button_duplicate))
    end
    find("body").send_keys :escape

    within(".Box-row", text: alfa_variant.own_name) do
      find("action-menu > button").click
      expect(page).to have_button(I18n.t(:button_duplicate))
    end
  end

  it "reorders root types via drag and drop", :selenium do
    visit types_path

    expect(bug_type.position).to be < feature_type.position

    drag_handle = page.find("[data-draggable-id='#{feature_type.id}'] .DragHandle")
    target = page.find("[data-draggable-id='#{bug_type.id}']")

    drag_n_drop_element(from: drag_handle, to: target)

    wait_for { feature_type.reload.position }.to be < bug_type.reload.position
  end

  it "reorders a root type via the async 'Move' submenu" do
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
end

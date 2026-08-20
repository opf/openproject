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

RSpec.describe "Work package type variants tab", :js, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }

  let!(:hardware) { create(:type_variant, type: bug_type, variant_name: "Hardware") }

  let(:tab_path) { type_variants_path(type_id: bug_type.id) }

  before do
    login_as(admin)
    visit tab_path
  end

  def open_variant_menu
    within(".Box-row", text: hardware.variant_name) { find("action-menu > button").click }
  end

  it "lists the type's variants" do
    expect(page).to have_link(hardware.variant_name,
                              href: edit_type_details_path(type_id: bug_type.id, variant_id: hardware.id))
  end

  it "stays on the tab after activating a variant in new projects" do
    open_variant_menu
    click_on I18n.t("types.index.make_default")

    expect(page).to have_current_path(tab_path)
    expect(page).to have_text(I18n.t("types.index.enabled_in_new_projects"))
    expect(hardware.reload).to be_enabled_in_new_projects
  end

  it "stays on the tab after deactivating a variant in new projects" do
    hardware.update!(enabled_in_new_projects: true)
    refresh

    open_variant_menu
    click_on I18n.t("types.index.remove_default")

    expect(page).to have_current_path(tab_path)
    expect(hardware.reload).not_to be_enabled_in_new_projects
  end

  it "stays on the tab after deleting a variant" do
    open_variant_menu
    accept_confirm { click_on I18n.t(:button_delete) }

    expect(page).to have_current_path(tab_path)
    expect(page).to have_text(I18n.t("types.edit.variants.blankslate.title"))
    expect(TypeVariant).not_to exist(id: hardware.id)
  end

  it "returns to the tab when the add-variant wizard is cancelled" do
    find_test_selector("add-type-variant").click

    expect(page).to have_text(I18n.t("types.creation_wizard.add_variant", name: bug_type.name))

    click_on I18n.t(:button_cancel), match: :first

    expect(page).to have_current_path(tab_path)
  end
end

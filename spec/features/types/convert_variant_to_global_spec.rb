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

RSpec.describe "Convert a project-owned variant to global", :js, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project) }

  let!(:owned) { create(:project_owned_type_variant, type: bug_type, project:, variant_name: "Internal") }

  let(:tab_path) { type_variants_path(type_id: bug_type.id) }
  let(:convert_action) { I18n.t("types.index.convert_to_global") }
  let(:confirm_dialog) { I18n.t("types.index.convert_to_global") }
  let(:rename_dialog) { I18n.t("types.index.convert_to_global_rename.title") }

  before do
    login_as(admin)
    visit tab_path
  end

  it "confirms, then makes the variant global" do
    within(find_test_selector("type-variant-#{owned.id}")) { find("action-menu > button").click }
    click_on convert_action

    within_dialog(confirm_dialog) do
      expect(page).to have_text("The project admin will no longer be able to edit it")
      click_on I18n.t("types.index.convert_to_global_dialog.confirm")
    end

    expect_flash(type: :success, message: I18n.t("types.index.convert_to_global_notice", name: owned.composite_name))
    expect(owned.reload.project_id).to be_nil
  end

  context "when a global variant already carries the name" do
    let!(:clashing_global) { create(:type_variant, type: bug_type, variant_name: "Internal") }

    it "asks for a new name, validates it, then confirms and converts" do
      within(find_test_selector("type-variant-#{owned.id}")) { find("action-menu > button").click }
      click_on convert_action

      within_dialog(rename_dialog) do
        fill_in "Name", with: "Internal"
        click_on I18n.t("types.index.convert_to_global_rename.confirm")
        expect(page).to have_text("Name has already been taken")

        fill_in "Name", with: "Shared config"
        click_on I18n.t("types.index.convert_to_global_rename.confirm")
      end

      within_dialog(confirm_dialog) do
        click_on I18n.t("types.index.convert_to_global_dialog.confirm")
      end

      expect_flash(type: :success,
                   message: I18n.t("types.index.convert_to_global_notice", name: "#{bug_type.name}: Shared config"))
      expect(owned.reload).to have_attributes(project_id: nil, variant_name: "Shared config")
    end
  end

  context "when the variant inherits an aspect from a project-specific variant" do
    before do
      owned.update!(workflows_source: create(:project_owned_type_variant, type: bug_type, project:,
                                                                          variant_name: "Sibling"))
    end

    it "refuses with an error flash and opens no dialog" do
      within(find_test_selector("type-variant-#{owned.id}")) { find("action-menu > button").click }
      click_on convert_action

      expect_flash(type: :error, message: I18n.t("types.index.convert_to_global_blocked").strip)
      expect(page).to have_no_css("dialog[open]")
      expect(owned.reload).to be_project_owned
    end
  end
end

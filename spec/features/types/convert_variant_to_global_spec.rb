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

RSpec.describe "Convert a project-owned variant to global", :js do
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

  it "warns that the project's workflow becomes global too, and converts it" do
    workflow = create(:project_owned_workflow, project:, name: "Bookshop flow")
    owned.update!(workflow:)

    within(find_test_selector("type-variant-#{owned.id}")) { find("action-menu > button").click }
    click_on convert_action

    within_dialog(confirm_dialog) do
      expect(page).to have_text(%(Its workflow "#{workflow.name}" belongs to this project))
      click_on I18n.t("types.index.convert_to_global_dialog.confirm")
    end

    expect_flash(type: :success, message: I18n.t("types.index.convert_to_global_notice", name: owned.composite_name))
    expect(workflow.reload.project_id).to be_nil
  end

  context "when the variant uses a global workflow" do
    before { owned.update!(workflow: create(:named_workflow, name: "Standard flow")) }

    it "says nothing about the workflow" do
      within(find_test_selector("type-variant-#{owned.id}")) { find("action-menu > button").click }
      click_on convert_action

      within_dialog(confirm_dialog) do
        expect(page).to have_text("The project admin will no longer be able to edit it")
        expect(page).to have_no_text("belongs to this project")
      end
    end
  end

  context "when a global variant already carries the name" do
    let!(:clashing_global) { create(:type_variant, type: bug_type, variant_name: "Internal") }

    it "confirms first, then asks for a new name and converts" do
      within(find_test_selector("type-variant-#{owned.id}")) { find("action-menu > button").click }
      click_on convert_action

      within_dialog(confirm_dialog) do
        click_on I18n.t("types.index.convert_to_global_dialog.confirm")
      end

      within_dialog(rename_dialog) do
        fill_in "Name", with: "Internal"
        click_on I18n.t("types.index.convert_to_global_rename.confirm")
        expect(page).to have_text("Name has already been taken")

        fill_in "Name", with: "Shared config"
        click_on I18n.t("types.index.convert_to_global_rename.confirm")
      end

      expect_flash(type: :success,
                   message: I18n.t("types.index.convert_to_global_notice", name: "#{bug_type.name}: Shared config"))
      expect(owned.reload).to have_attributes(project_id: nil, variant_name: "Shared config")
    end
  end
end

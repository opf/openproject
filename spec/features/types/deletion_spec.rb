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

RSpec.describe "Deleting a work package type", :js, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:dialog_id) { WorkPackageTypes::Types::TypeDeletionDialogComponent::DIALOG_ID }

  before { login_as(admin) }

  def click_delete(type)
    visit types_path

    within("[data-draggable-id='#{type.id}'] .Box-header") do
      find("action-menu > button").click
      click_on I18n.t(:button_delete)
    end
  end

  # The dialog arrives over a turbo stream, and a click lands nowhere until the native
  # dialog element has finished opening.
  def within_deletion_dialog(&)
    expect(page).to have_css("##{dialog_id}[open]")

    within("##{dialog_id}", &)
  end

  context "when projects use the type" do
    let!(:type) { create(:type, name: "Bug") }
    let!(:project) { create(:project, name: "Apollo", types: [type]) }
    let!(:other_project) { create(:project, name: "Gemini", types: [type]) }

    it "names the projects it will be removed from, then removes it from them" do
      click_delete(type)

      within_deletion_dialog do
        expect(page).to have_text(I18n.t("types.index.delete.projects", count: 2))
        expect(page).to have_test_selector("type-deletion-projects", text: "Apollo")
        expect(page).to have_test_selector("type-deletion-projects", text: "Gemini")

        click_on I18n.t(:button_delete)
      end

      expect(page).to have_text(I18n.t(:notice_successful_delete))
      expect(page).to have_no_text("Bug")

      expect { type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(project.reload.enabled_types).to be_empty
      expect(other_project.reload.enabled_types).to be_empty
    end

    it "keeps the type when the dialog is cancelled" do
      click_delete(type)

      within_deletion_dialog { click_on I18n.t(:button_cancel) }

      expect(page).to have_no_css("##{dialog_id}")
      expect(type.reload).to be_present
      expect(project.reload.enabled_types).to contain_exactly(type)
    end
  end

  context "when no project uses the type" do
    let!(:type) { create(:type, name: "Bug") }

    it "warns that the deletion cannot be undone, then deletes it" do
      click_delete(type)

      within_deletion_dialog do
        expect(page).to have_text(I18n.t("types.index.delete.description"))
        expect(page).to have_no_test_selector("type-deletion-projects")

        click_on I18n.t(:button_delete)
      end

      expect(page).to have_text(I18n.t(:notice_successful_delete))
      expect { type.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when work packages still use the type" do
    let!(:type) { create(:type, name: "Bug") }
    let!(:project) { create(:project, name: "Apollo", types: [type]) }
    let!(:work_package) { create(:work_package, project:, type:) }

    it "refuses with an error flash instead of opening a dialog" do
      click_delete(type)

      expect(page).to have_text("cannot be deleted")
      expect(page).to have_no_css("##{dialog_id}")
      expect(page).to have_link("this view")

      expect(type.reload).to be_present
      expect(project.reload.enabled_types).to contain_exactly(type)
    end
  end
end

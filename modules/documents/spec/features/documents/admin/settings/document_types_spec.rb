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

RSpec.describe "Document types admin", :js do
  include Flash::Expectations
  include EnumerationAdminHelpers

  current_user { create(:admin) }

  def enumeration_list_selector = "#document-types-table > .op-border-box-table--rows"
  def enumeration_item_selector = :row
  def enumeration_actions_label = I18n.t("documents.document_type_actions")

  def within_document_type_row(document_type, &)
    within_enumeration_list { within(:row, document_type.name, &) }
  end

  def drag_document_type(document_type, after:)
    handle = enumeration_drag_handle(document_type)
    target = enumeration_row(after)
    offset_y = (target.native.rect.height / 2) - [6, target.native.rect.height / 4].min

    perform_native_drag(source: handle, target:, offset_y: offset_y.round)

    # Assert Pragmatic DnD tore down its own honey-pot overlay, so a regression
    # leaving it stuck is caught here rather than as an unrelated click failure.
    expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
  end

  context "when managing document types" do
    let!(:default_document_type) { create(:document_type, is_default: true, name: "Note") }

    it "can be managed (created, updated, deleted)" do
      visit admin_settings_document_types_path

      within_document_type_row(default_document_type) do
        expect(page).to have_text("Note")
        expect(page).to have_text("Default")
      end

      within_test_selector("admin-document-types-subheader") do
        click_on "Type"
      end

      fill_in "Name", with: "Documentation"
      check "Default"
      click_on("Save")

      expect_and_dismiss_flash(message: "Successful update.")

      # we are redirected back to the index page
      expect(page).to have_current_path(admin_settings_document_types_path)

      new_document_type = DocumentType.last

      # The new document type is shown in the list as the default document type
      within_document_type_row(new_document_type) do
        expect(page).to have_text("Documentation")
        expect(page).to have_text("Default")
      end

      # Since the new document type is now the default, the former default looses that flag
      within_document_type_row(default_document_type) do
        expect(page).to have_text("Note")
        expect(page).to have_no_text("Default")
      end

      click_link "Documentation"

      expect(page).to have_text("Making this document type the default")
      expect(page).to have_no_text("priority")

      fill_in "Name", with: "Report"
      click_on("Save")

      expect_and_dismiss_flash(message: "Successful update.")

      within_document_type_row(new_document_type.reload) do
        expect(page).to have_text("Report")
        expect(page).to have_text("Default")
      end

      expect(DocumentType).to exist(name: "Report")
      expect(DocumentType).not_to exist(name: "Documentation")

      # It allows deleting document types
      within_enumeration_menu(new_document_type) do |menu|
        menu.find(:menuitem, I18n.t(:button_delete)).click
      end

      within_dialog("Delete document type") do
        expect(page).to have_heading "Delete this document type?"
        expect(page).to have_text 'The type "Report" is currently unused. ' \
                                  "Deleting this type will have no effect on existing documents."

        click_on "Delete permanently"
      end

      expect_and_dismiss_flash(message: "Successful deletion.")

      expect(page).to have_no_text("Report")

      # Since the old default is deleted another is now the default.
      within_document_type_row(default_document_type) do
        expect(page).to have_text("Note")
        expect(page).to have_no_text("Default")
      end
    end
  end

  context "with multiple types having documents" do
    let!(:type_with_documents) { create(:document_type, name: "Type with documents") }
    let!(:another_type) { create(:document_type, name: "Another type") }
    let!(:unused_type) { create(:document_type, name: "Unused type") }
    let!(:document) { create(:document, type: type_with_documents) }

    it "reassigns documents when deleting a document type" do
      visit admin_settings_document_types_path

      within_enumeration_menu(type_with_documents) do |menu|
        menu.find(:menuitem, I18n.t(:button_delete)).click
      end

      within_dialog("Delete document type") do
        expect(page).to have_heading "Delete this document type?"
        expect(page).to have_text 'The type "Type with documents" is currently being used in 1 document. ' \
                                  "Please select which type to reassign them to."

        select another_type.name, from: "Reassign documents to"
        click_on "Delete permanently"
      end

      expect_and_dismiss_flash(message: "Successful deletion.")

      expect(DocumentType).not_to exist(name: "Type with documents")
      expect(document.reload.type).to eq another_type

      within_document_type_row(another_type) do
        expect(page).to have_css("[role='cell'][aria-colindex='2']", exact_text: "1", normalize_ws: true)
      end

      # It allows deleting unused document types
      within_enumeration_menu(unused_type) do |menu|
        menu.find(:menuitem, I18n.t(:button_delete)).click
      end

      within_dialog("Delete document type") do
        expect(page).to have_heading "Delete this document type?"
        expect(page).to have_text 'The type "Unused type" is currently unused. ' \
                                  "Deleting this type will have no effect on existing documents."

        click_on "Delete permanently"
      end

      expect_and_dismiss_flash(message: "Successful deletion.")

      expect(DocumentType).not_to exist(name: "Unused type")

      # Last remaining type cannot be deleted
      within_enumeration_menu(another_type) do |menu|
        menu.find(:menuitem, I18n.t(:button_delete)).click
      end

      within_dialog("Cannot delete document type") do
        expect(page).to have_heading "Cannot delete the last document type"
        expect(page).to have_text "There must always be at least one document type configured. " \
                                  "Create another one first if you want to delete this one."

        click_on "Close"
      end
    end
  end

  context "with three document types" do
    let!(:alpha) { create(:document_type, name: "Alpha") }
    let!(:beta) { create(:document_type, name: "Beta") }
    let!(:gamma) { create(:document_type, name: "Gamma") }

    before do
      gamma.move_to_top
      beta.move_to_top
      alpha.move_to_top
    end

    # The moved row's menu is reopened after the morph: only a refreshed menu
    # hides the directions that stopped being available.
    it "reorders through the move menu twice across a morph" do
      visit admin_settings_document_types_path

      expect_enumeration_order("Alpha", "Beta", "Gamma")

      move_enumeration(gamma, I18n.t(:label_sort_highest))

      expect_enumeration_move_settled("Gamma", "Alpha", "Beta")

      within_enumeration_move_submenu(gamma) do |submenu|
        expect(submenu).to have_no_selector(:menuitem, I18n.t(:label_sort_highest))
        expect(submenu).to have_no_selector(:menuitem, I18n.t(:label_sort_higher))
        expect(submenu).to have_selector(:menuitem, I18n.t(:label_sort_lower))
        submenu.find(:menuitem, I18n.t(:label_sort_lowest)).click
      end

      expect_enumeration_move_settled("Alpha", "Beta", "Gamma")

      refresh

      expect_enumeration_order("Alpha", "Beta", "Gamma")
    end

    # The second drag runs without a reload on purpose: the sortable root
    # re-registers Pragmatic's drop targets after a morph, and only a drag that
    # follows a completed morph exercises that repair.
    it "reorders by dragging twice across a morph", :selenium do
      visit admin_settings_document_types_path

      expect_enumeration_order("Alpha", "Beta", "Gamma")

      drag_document_type(alpha, after: beta)

      expect_enumeration_move_settled("Beta", "Alpha", "Gamma")

      drag_document_type(beta, after: gamma)

      expect_enumeration_move_settled("Alpha", "Gamma", "Beta")

      refresh

      expect_enumeration_order("Alpha", "Gamma", "Beta")
    end
  end

  context "with a single document type" do
    let!(:only_type) { create(:document_type, name: "Only type") }

    it "hides the Move submenu and renders one separator" do
      visit admin_settings_document_types_path

      within_enumeration_menu(only_type) do |menu|
        expect(menu).to have_selector(:menuitem, I18n.t(:button_edit))
        expect(menu).to have_selector(:menuitem, I18n.t(:button_delete))
        expect(menu).to have_no_selector(:menuitem, I18n.t(:button_move))
        expect(menu).to have_css("li.ActionList-sectionDivider", count: 1)
      end
    end
  end

  context "with non-admin user" do
    current_user { create(:user) }

    it "is not accessible" do
      visit admin_settings_document_types_path

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end
end

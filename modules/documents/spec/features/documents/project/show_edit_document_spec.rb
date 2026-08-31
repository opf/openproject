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
require_module_spec_helper

RSpec.describe "Show/Edit Document View",
               :js,
               :selenium do
  include_context "with hocuspocus"

  shared_let(:project) { create(:project) }
  shared_let(:member_role) { create(:existing_project_role, permissions: %i[view_documents manage_documents]) }
  shared_let(:member) { create(:user, member_with_roles: { project => member_role }) }

  let(:document_types) do
    %w[Specification Report].map { create(:document_type, name: it) }
  end
  let(:document) do
    create(:document, :collaborative, project:, title: "Collaborative document", type: document_types.first)
  end

  current_user { member }

  it "renders a collaborative document",
     with_settings: { real_time_text_collaboration_enabled: true } do
    visit document_path(document)

    expect(page).to have_content("Collaborative document")

    aggregate_failures "can see live users" do
      within_test_selector("live-events") do
        expect(page).to have_content("1 active editor")
      end
    end

    aggregate_failures "can edit document title" do
      within_test_selector("document-page-header") do
        click_button accessible_name: "Document actions"
        expect(page).to have_selector :menuitem, "Edit title"

        click_on "Edit title"

        fill_in "document_title", with: ""
        click_on "Save"
        expect(page).to have_content("Title can't be blank")

        fill_in "document_title", with: "Updated collaborative document"
        click_on "Save"

        expect(page).to have_content("Updated collaborative document")

        click_button accessible_name: "Document actions"
        click_on "Edit title"
        click_on "Cancel"
        expect(page).to have_content("Updated collaborative document")
      end
    end

    aggregate_failures "can change document type" do
      within_test_selector("document-info-line") do
        click_button "Specification"
        click_on "Report"
        expect(page).to have_button("Report")
      end
      expect(document.reload.type).to eq(document_types[1])
    end

    aggregate_failures "can edit document content" do
      editor = FormFields::Primerized::BlockNoteEditorInput.new
      editor.fill_in("This is the new **content**.")

      expect(editor.element).to have_content("This is the new content.") # bold is applied
    end
  end

  context "with real-time collaboration disabled",
          with_settings: { real_time_text_collaboration_enabled: false } do
    it "renders a notice about collaboration being disabled" do
      visit document_path(document)

      expect(page).to have_content("Unable to open document because real-time text collaboration is disabled. " \
                                   "Please contact your administrator to enable real-time text collaboration " \
                                   "if you want to access this document.")
    end
  end

  context "without view documents permission" do
    let(:user) { create(:user) }

    current_user { user }

    it "renders a not found message" do
      visit document_path(document)
      expect(page).to have_text("[Error 404] The page you were trying to access doesn't exist or has been removed.")
    end
  end
end

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

require_relative "support/documents_index_page"

RSpec.describe "Create Document",
               :js,
               :selenium do
  shared_let(:project) { create(:project) }
  shared_let(:manager_role) { create(:existing_project_role, permissions: %i[view_documents manage_documents]) }
  shared_let(:viewer_role) { create(:existing_project_role, permissions: [:view_documents]) }
  shared_let(:manager) { create(:user, member_with_roles: { project => manager_role }) }
  shared_let(:viewer) { create(:user, member_with_roles: { project => viewer_role }) }
  shared_let(:document_types) { create_list(:document_type, 3) }

  let(:index_page) { Documents::Pages::ListPage.new(project) }

  current_user { manager }

  context "for collaborative documents", with_settings: { real_time_text_collaboration_enabled: true } do
    it "creates a new document via +Document buttons" do
      index_page.visit!

      index_page.expect_blank_slate_with_primary_action

      aggregate_failures "pre-filled document title" do
        within_test_selector("documents-sub-header") do
          click_on "Document"
        end

        within_test_selector("document-page-header") do
          expect(page).to have_field("document_title", with: "New document")
          expect(page).to have_button(document_types.first.name)

          fill_in "document_title", with: ""
          click_on "Save"
          expect(page).to have_content("Title can't be blank")

          fill_in "document_title", with: "My collaborative document"
          click_on "Save"

          expect(page).to have_content("My collaborative document")
        end
      end
    end
  end

  context "for classic documents", with_settings: { real_time_text_collaboration_enabled: false } do
    let(:editor) { Components::WysiwygEditor.new }

    it "creates a new document via `/projeects/:id/documents/new` route" do
      index_page.visit!

      within_test_selector("documents-sub-header") do
        click_on "Document"
      end

      select document_types.second.name, from: "Type"
      fill_in "Title", with: "My classic document"
      editor.editor_element.send_keys("This is a classic document.")

      click_on "Create"
      expect(page).to have_current_path(project_documents_path(project))

      expect(page).to have_css(".Box-row", text: "My classic document") &
                       have_test_selector("label-legacy", text: "Legacy")
    end
  end

  context "without manage documents permission" do
    current_user { viewer }

    it "does not render the new document button" do
      index_page.visit!

      within_test_selector("documents-sub-header") do
        expect(page).to have_no_button("Document")
      end

      within_test_selector("documents-list-blank-slate") do
        expect(page).to have_no_link("Document")
      end
    end
  end
end

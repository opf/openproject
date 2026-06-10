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

require "rails_helper"

RSpec.describe "BlockNote editor rendering", :js, :selenium, with_settings: { real_time_text_collaboration_enabled: true } do
  include_context "with hocuspocus"

  let(:admin) { create(:admin) }
  let(:document) { create(:document, :collaborative) }
  let(:editor) { FormFields::Primerized::BlockNoteEditorInput.new }

  before do
    login_as(admin)
  end

  it "renders the BlockNote editor in the users locale" do
    admin.update!(language: "de")
    visit document_path(document)

    expect(page).to have_test_selector("blocknote-document-description")
    expect(editor.content).not_to include("Überschrift")

    editor.open_command_dialog
    expect(editor.content).to include("Überschrift")
  end

  it "renders the BlockNote editor in english if the users locale is not available for BlockNote" do
    admin.update!(language: "af")
    visit document_path(document)

    expect(page).to have_test_selector("blocknote-document-description")
    expect(editor.content).not_to include("Heading")

    editor.open_command_dialog
    expect(editor.content).to include("Heading")
  end

  context "when real time text collaboration is disabled",
          with_settings: { real_time_text_collaboration_enabled: false } do
    it "does not render the BlockNote editor" do
      visit document_path(document)

      expect(page).to have_no_test_selector("blocknote-document-description")
      expect(page).to have_test_selector(
        "collaboration-disabled-notice",
        text: "Unable to open document because real-time text collaboration is disabled. " \
              "Please contact your administrator to enable real-time text collaboration " \
              "if you want to access this document."
      )
    end
  end

  describe "with op-blocknote-extensions" do
    it "renders the BlockNote editor with custom menu entries for work package linking" do
      visit document_path(document)

      expect(page).to have_test_selector("blocknote-document-description")
      editor.fill_in("/openproject")
      expect(editor.content).to have_content("Link existing work package")
    end

    it "orders results of the work package search by updated at DESC" do
      create(:work_package, project: document.project, subject: "BBB test", updated_at: 4.hours.ago)
      create(:work_package, project: document.project, subject: "AAA test", updated_at: 2.hours.ago)
      create(:work_package, project: document.project, subject: "CCC test", updated_at: 3.hours.ago)

      visit document_path(document)
      expect(page).to have_test_selector("blocknote-document-description")

      editor.open_add_work_package_dialog
      editor.search_work_package("test")
      expect(editor.element).to have_content("AAA test") # wait for dropdown to open
      expect(editor.element.text).to match(/AAA test.*CCC test.*BBB test/m)
    end

    context "when inserting work package links into the editor" do
      let(:status) { create(:status, name: "Open") }
      let(:type) { create(:type, name: "Life Goals") }
      let(:work_package) do
        create(:work_package,
               project: document.project,
               subject: "pet a tiger",
               status:,
               type:)
      end

      before { work_package } # force eager creation before visiting the page

      it "inserts link work package cards with slash command" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.open_add_work_package_dialog
        editor.search_and_select_work_package("tiger", "pet a tiger")

        expect(editor.element).to have_no_text("Link existing work package") # search dialog is closed
        expect(editor.element).to have_no_text("…") # work package is loaded
        expect(editor.element.text).to match(/##{work_package.display_id}\sLIFE GOALS\sOpen\spet a tiger/)

        # Capybara's have_link seems not to work in a shadow dom, so it's tested via the property
        expect(editor.element.find_link(text: "pet a tiger").native.property("href")).to end_with("/wp/#{work_package.id}")

        editor.wait_for_autosave { document.reload.description&.include?("##{work_package.id}") }
      end

      it "inserts an xxs inline link via # notation" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.element.send_keys("#tiger")
        editor.wait_for_shadow_content("pet a tiger")
        send_keys(:enter)
        expect(editor.element).to have_no_text("#tiger") # wait for work package to load

        expect(editor.element).to have_no_text("…") # inline chip loading state
        expect(editor.element.text).to match(/##{work_package.display_id}/)
        # xxs chip shows only the ID — no title link

        editor.wait_for_autosave { document.reload.description&.include?("##{work_package.id}") }
      end

      it "inserts an xs inline link via ## notation" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.element.send_keys("##tiger")
        editor.wait_for_shadow_content("pet a tiger")
        send_keys(:enter)
        expect(editor.element).to have_no_text("##tiger") # wait for work package to load

        expect(editor.element).to have_no_text("…")
        expect(editor.element.text).to match(/##{work_package.display_id}\sLIFE GOALS\spet a tiger/)
        # Capybara's have_link seems not to work in a shadow dom, so it's tested via the property
        expect(editor.element.find_link(text: "pet a tiger").native.property("href"))
          .to end_with("/wp/#{work_package.id}")

        editor.wait_for_autosave { document.reload.description&.include?("##{work_package.id}") }
      end

      it "inserts an s inline link via ### notation" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.element.send_keys("###tiger")
        editor.wait_for_shadow_content("pet a tiger")
        send_keys(:enter)
        expect(editor.element).to have_no_text("###tiger") # wait for work package to load

        expect(editor.element).to have_no_text("…")
        expect(editor.element.text).to match(/##{work_package.display_id}\sLIFE GOALS\sOpen\spet a tiger/)
        # Capybara's have_link seems not to work in a shadow dom, so it's tested via the property
        expect(editor.element.find_link(text: "pet a tiger").native.property("href"))
          .to end_with("/wp/#{work_package.id}")

        editor.wait_for_autosave { document.reload.description&.include?("##{work_package.id}") }
      end

      describe "CTRL-Z undo behavior" do
        it "undoes typed text with CTRL-Z" do
          visit document_path(document)
          expect(page).to have_test_selector("blocknote-document-description")

          editor.fill_in("X")
          expect(editor.element).to have_text("X")

          editor.undo

          expect(editor.element).to have_no_text("X")
        end

        it "undoes an inline work package chip inserted via # notation with CTRL-Z" do
          visit document_path(document)
          expect(page).to have_test_selector("blocknote-document-description")

          editor.element.send_keys("#tiger")
          editor.wait_for_shadow_content("pet a tiger")
          send_keys(:enter)
          expect(editor.element).to have_no_text("#tiger") # chip replaced autocomplete text

          expect(editor.element).to have_no_text("…") # chip finished loading
          expect(editor.element).to have_text(/##{work_package.display_id}/)

          editor.undo

          expect(editor.element).to have_no_text(/##{work_package.display_id}/)
        end
      end
    end
  end
end

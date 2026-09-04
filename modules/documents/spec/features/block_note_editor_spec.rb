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

  it "hands the project of the document to the editor, so a work package can be created in it" do
    visit document_path(document)

    expect(page).to have_test_selector("blocknote-document-description")
    expect(find("op-block-note", visible: false)["project-id"]).to eq(document.project_id.to_s)
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

  context "when running with a relative_url_root and non-proxied frontend assets",
          js: false,
          with_env: { "OPENPROJECT_DISABLE_DEV_ASSET_PROXY" => "1" } do
    before do
      allow(Rails.application.config).to receive(:relative_url_root).and_return("/openproject")
    end

    it "renders the BlockNote shadow-DOM stylesheet urls prefixed with the relative url root" do
      visit document_path(document)

      block_note_element = find("op-block-note", visible: false)
      expect(block_note_element["blocknote-stylesheet-url"])
        .to match(%r{\A/openproject/assets/frontend/blocknote(.*)\.css\z})
      expect(block_note_element["shadow-dom-stylesheet-url"])
        .to match(%r{\A/openproject/assets/frontend/styles(.*)\.css\z})
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
      let!(:work_package) do
        create(:work_package,
               project: document.project,
               subject: "pet a tiger",
               status:,
               type:)
      end

      it "inserts link work package cards with slash command" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.open_add_work_package_dialog
        editor.search_and_select_work_package("tiger", "pet a tiger")

        expect(editor.element).to have_no_text("Link existing work package") # search dialog is closed
        expect(editor.element).to have_no_text("Loading")
        expect(editor.element.text).to match(/LIFE GOALS\s##{work_package.display_id}\sOpen\spet a tiger/)

        # Capybara's have_link seems not to work in a shadow dom, so it's tested via the property
        expect(editor.element.find_link(text: "pet a tiger").native.property("href")).to end_with("/wp/#{work_package.id}")

        editor.wait_for_autosave { document.reload.description&.include?("[####{work_package.id}](https://openproject.local/wp/#{work_package.id})") }
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

        editor.wait_for_autosave { document.reload.description&.include?("[##{work_package.id}](https://openproject.local/wp/#{work_package.id})") }
      end

      it "inserts an xs inline link via ## notation" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.element.send_keys("##tiger")
        editor.wait_for_shadow_content("pet a tiger")
        send_keys(:enter)
        expect(editor.element).to have_no_text("##tiger") # wait for work package to load

        expect(editor.element).to have_no_text("…")
        expect(editor.element.text).to match(/##{work_package.display_id}LIFE GOALSpet a tiger/)
        # Capybara's have_link seems not to work in a shadow dom, so it's tested via the property
        expect(editor.element.find_link(text: "pet a tiger").native.property("href"))
          .to end_with("/wp/#{work_package.id}")

        editor.wait_for_autosave { document.reload.description&.include?("[###{work_package.id}](https://openproject.local/wp/#{work_package.id})") }
      end

      it "inserts an s inline link via ### notation" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.element.send_keys("###tiger")
        editor.wait_for_shadow_content("pet a tiger")
        send_keys(:enter)
        expect(editor.element).to have_no_text("###tiger") # wait for work package to load

        expect(editor.element).to have_no_text("…")
        expect(editor.element.text).to match(/##{work_package.display_id}LIFE GOALSOpenpet a tiger/)
        # Capybara's have_link seems not to work in a shadow dom, so it's tested via the property
        expect(editor.element.find_link(text: "pet a tiger").native.property("href"))
          .to end_with("/wp/#{work_package.id}")

        editor.wait_for_autosave { document.reload.description&.include?("####{work_package.id}") }
      end

      it "allows deleting text with Backspace after inserting an inline work package link (bugfix STC-806)" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.element.send_keys("#tiger")
        editor.wait_for_shadow_content("pet a tiger")
        send_keys(:enter)
        expect(editor.element).to have_no_text("#tiger")
        expect(editor.element).to have_no_text("…")
        expect(editor.element).to have_text(/##{work_package.display_id}/)

        # Type right after the chip and delete it again with Backspace. Do NOT click / move the caret
        # first — the bug only manifested when typing immediately after insertion (moving the caret
        # elsewhere "fixed" it). send_keys (session-level) targets the already-focused editor.
        send_keys("abc")
        expect(editor.element).to have_text("abc")

        send_keys(:backspace, :backspace, :backspace)

        expect(editor.element).to have_no_text("abc")
        expect(editor.element).to have_text(/##{work_package.display_id}/)
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

    context "when creating a work package from the document" do
      let(:type) { create(:type_task) }
      let(:project) { create(:project, name: "Documented project", types: [create(:type_bug), type]) }
      let(:document) { create(:document, :collaborative, project:) }
      let!(:release_note) do
        create(:string_wp_custom_field, name: "Release note", is_required: true, types: [type], projects: [project])
      end
      let!(:default_status) { create(:status, is_default: true) }
      let!(:default_priority) { create(:priority, is_default: true) }
      let!(:other_project) { create(:project, name: "Another project", types: [type]) }

      it "creates it in the project of the document, with the fields the chosen type requires" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")

        editor.open_create_work_package_dialog

        within editor.create_work_package_form do
          expect(page).to have_field("op-bn-create-wp-project", with: project.name)

          select type.name, from: "op-bn-create-wp-type"
          fill_in "op-bn-create-wp-subject", with: "Write the release notes"
          fill_in "op-bn-create-wp-#{release_note.attribute_name(:camel_case)}", with: "16.0"

          click_on "Create"
        end

        expect(page).to have_no_css("[data-testid='create-wp-modal']")
        expect(editor.element).to have_text("Write the release notes")

        work_package = WorkPackage.last
        expect(work_package.project).to eq(project)
        expect(work_package.type).to eq(type)
        expect(work_package.subject).to eq("Write the release notes")
        expect(work_package.custom_value_for(release_note).value).to eq("16.0")
      end
    end
  end
end

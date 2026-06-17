# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "Work package activity tab comment editor",
               :js,
               :with_cuprite do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:work_package) { create(:work_package, project:, author: admin) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  describe "Dismiss strategy" do
    current_user { admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    context "when editor content is empty" do
      it "is dismissable via keyboard Esc" do
        expect_editor_to_be_dismissed do
          activity_tab.dismiss_comment_editor_with_esc
        end
      end

      it "shows a Dismiss button (not Cancel) for new comments" do
        activity_tab.add_comment(text: "Sample text", save: false)
        activity_tab.clear_comment

        page.within_test_selector("op-work-package-journal-form") do
          expect(page).to have_button("Dismiss")
          expect(page).to have_no_button("Cancel")
        end
      end

      it "is dismissable via Dismiss button" do
        expect_editor_to_be_dismissed do
          activity_tab.dismiss_comment_editor_with_cancel_button
        end
      end

      def expect_editor_to_be_dismissed
        activity_tab.add_comment(text: "Sample text", save: false)
        activity_tab.clear_comment

        activity_tab.expect_focus_on_editor
        yield

        expect(page).not_to have_test_selector("op-work-package-journal-form-element")
      end
    end

    context "when editor has content" do
      context "and the user confirms the dismissal" do
        it "requires confirmation to dismiss via keyboard Esc" do
          expect_editor_to_be_dismissed_with_confirmation do
            activity_tab.dismiss_comment_editor_with_esc
          end
        end

        it "requires confirmation to dismiss via Dismiss button" do
          expect_editor_to_be_dismissed_with_confirmation do
            activity_tab.dismiss_comment_editor_with_cancel_button
          end
        end

        it "shows the updated confirmation message when dismissing a new comment" do
          activity_tab.add_comment(text: "Sample text", save: false)
          activity_tab.expect_focus_on_editor

          expected_message = "Are you sure you want to dismiss your comment? The content that you have written will be lost."
          accept_alert(expected_message) do
            activity_tab.dismiss_comment_editor_with_cancel_button
          end

          expect(page).not_to have_test_selector("op-work-package-journal-form-element")
        end

        def expect_editor_to_be_dismissed_with_confirmation(&)
          activity_tab.add_comment(text: "Sample text", save: false)

          activity_tab.expect_focus_on_editor

          accept_alert(&)

          expect(page).not_to have_test_selector("op-work-package-journal-form-element")
        end
      end

      context "and the user cancels the dismissal" do
        it "does not dismiss the editor" do
          activity_tab.add_comment(text: "Sample text", save: false)

          activity_tab.expect_focus_on_editor

          dismiss_confirm do
            activity_tab.dismiss_comment_editor_with_esc
          end

          activity_tab.expect_focus_on_editor

          page.within_test_selector("op-work-package-journal-form-element") do
            editor = activity_tab.get_editor_form_field_element
            expect(editor.input_element.text).to eq("Sample text")
          end
        end
      end
    end
  end

  describe "Accessibility" do
    current_user { admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "has the rich text editor aria labelled" do
      activity_tab.add_comment(text: "Sample text", save: false)

      activity_tab.expect_focus_on_editor
      expect(page).to have_selector(:rich_text, "Add a comment. Type @ to notify people.")

      activity_tab.clear_comment(blur: true)

      activity_tab.expect_blur_on_editor
      expect(page).to have_selector(:rich_text, "Add a comment. Type @ to notify people.")
    end
  end

  describe "Attachments" do
    let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
    let(:editor) { Components::WysiwygEditor.new }

    current_user { admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "can upload an image to a comment as an inline attachment" do
      activity_tab.add_comment(text: "Sample text", save: false)

      activity_tab.expect_focus_on_editor

      editor.drag_attachment(image_fixture.path, "An image caption")
      editor.wait_until_upload_progress_toaster_cleared

      attachment = Attachment.where(author: admin).last
      expect(attachment.container).to be_nil

      click_on "Submit"

      expect(page).to have_content("An image caption")
      journal = work_package.reload.journals.last
      expect(journal.attachments).to contain_exactly(attachment)
    end

    context "when editing an existing comment" do
      let(:comment) do
        create(:work_package_journal,
               user: admin,
               notes: notes_with_attachment(existing_attachment),
               journable: work_package,
               version: 2).tap do |journal|
                 journal.attachments << existing_attachment
                 journal.save(validate: false)
               end
      end

      let!(:existing_attachment) { create(:attachment, author: admin, container: nil) }

      it "updates the comment with new attachments" do
        expect(comment.reload.attachments).to contain_exactly(existing_attachment)

        activity_tab.edit_comment(comment, text: "Some notes", save: false)

        editor.drag_attachment(image_fixture.path, "An image caption")
        editor.wait_until_upload_progress_toaster_cleared

        click_on "Save"

        expect(page).to have_content("An image caption")
        newly_attached = Attachment.where(author: admin).last
        expect(comment.reload.attachments).to contain_exactly(newly_attached)
        expect(comment.reload.attachments).not_to include(existing_attachment)
      end

      def notes_with_attachment(attachment)
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment.id}/content">

          First attachment
        HTML
      end
    end
  end
end

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
require "features/page_objects/notification"

RSpec.describe "Upload attachment to documents",
               :js,
               :selenium,
               with_settings: {
                 journal_aggregation_time_minutes: 0
               } do
  let!(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_documents manage_documents] })
  end
  let!(:other_user) do
    create(:user,
           member_with_permissions: { project => %i[view_documents] },
           notification_settings: [build(:notification_setting, all: true)])
  end
  let!(:document_type) { create(:document_type, :experimental) }
  let(:project) { create(:project) }
  let(:attachments) { Components::Attachments.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }
  let(:attachments_list) { Components::AttachmentsList.new }

  before do
    login_as(user)
  end

  shared_examples "can upload an image in CKEditor" do
    it "can upload an image" do
      visit new_project_document_path(project)

      expect(page).to have_css('[data-test-selector="new-document"]', wait: 10)
      SeleniumHubWaiter.wait
      select(document_type.name, from: "Type")
      fill_in "Title", with: "New documentation"

      # adding an image via the attachments-list
      find_test_selector("op-attachments--drop-box").drop(image_fixture.path)

      editor.attachments_list.expect_attached("image.png")

      # adding an image
      editor.drag_attachment image_fixture.path, "Image uploaded on creation"
      editor.attachments_list.expect_attached("image.png", count: 2)
      editor.wait_until_upload_progress_toaster_cleared

      perform_enqueued_jobs do
        click_on "Create"

        # Wait for redirect to index and document to appear in list
        expect(page).to have_link("New documentation", wait: 10)
      end

      document = Document.last
      expect(document.title).to eq "New documentation"

      # Expect it to be present on the show page
      SeleniumHubWaiter.wait
      click_link "New documentation"
      expect(page).to have_current_path "/documents/#{document.id}", wait: 10
      expect(page).to have_css("#content img", count: 1)
      expect(page).to have_content("Image uploaded on creation")

      # Adding a second image
      # We should be using the 'Edit' button at the top but that leads to flickering specs
      # FIXME: yes indeed
      visit edit_document_path(document)

      # editor.click_and_type_slowly 'abc'
      SeleniumHubWaiter.wait

      editor.attachments_list.expect_attached("image.png", count: 2)

      editor.drag_attachment image_fixture.path, "Image uploaded the second time"

      editor.attachments_list.expect_attached("image.png", count: 3)

      editor.attachments_list.drag_enter
      editor.attachments_list.drop(image_fixture)

      editor.attachments_list.expect_attached("image.png", count: 4)

      editor.wait_until_upload_progress_toaster_cleared

      perform_enqueued_jobs do
        click_on "Save"

        # Expect both images to be present on the show page
        expect(page).to have_css("#content img", count: 2)
        expect(page).to have_content("Image uploaded on creation")
        expect(page).to have_content("Image uploaded the second time")
        attachments_list.expect_attached("image.png", count: 4)
      end

      # Expect a mail to be sent to the user having subscribed to all notifications
      expect(ActionMailer::Base.deliveries.size)
        .to eq 1

      expect(ActionMailer::Base.deliveries.last.to)
        .to contain_exactly(other_user.mail)

      expect(ActionMailer::Base.deliveries.last.subject)
        .to include "New documentation"
    end
  end

  context "with direct uploads (Regression #34285)", :with_direct_uploads do
    before do
      allow_any_instance_of(Attachment).to receive(:diskfile).and_return image_fixture # rubocop:disable RSpec/AnyInstance
    end

    it_behaves_like "can upload an image in CKEditor"
  end

  context "for internal uploads", with_direct_uploads: false do
    it_behaves_like "can upload an image in CKEditor"
  end

  shared_examples "can upload an image in BlockNote" do
    it "is possible to upload attachments from the editor" do
      expect(page).to have_no_css("img[alt='image.png']")
      editor.open_add_image_dialog

      expect do
        editor.attach_file(image_fixture.path)
        expect(editor.element).to have_css("img[alt='image.png'][src*='/api/v3/attachments/']")
      end.to change { document.attachments.count }.by(1)
    end
  end

  shared_examples "with non-whitelisted file types" do
    context "with an incompatible attachment allowlist",
            with_settings: { attachment_whitelist: %w[image/jpg] } do
      it "shows a nice error" do
        editor.open_add_image_dialog
        expect do
          editor.attach_file(image_fixture.path)
          expect(page).to have_content I18n.t("activerecord.errors.models.attachment.attributes.content_type.not_allowlisted",
                                              value: "image/png")
          expect(editor.element).to have_no_css("img[alt='image.png']")
        end.not_to change { document.attachments.count }
      end
    end
  end

  shared_examples "with attachments list in the sidebar" do
    it "is possible to upload attachments from the sidebar" do
      expect(page).to have_no_content("image.png")
      expect do
        attachments_list.drag_enter
        attachments_list.drop(image_fixture.path)
        expect(page).to have_no_css("op-toast") # wait for upload to finish
        attachments_list.expect_attached("image.png")
      end.to change { document.attachments.count }.by(1)
    end

    context "when an attachment is present" do
      let!(:attachment) { create(:attachment, filename: "test.jpg", container: document) }

      before do
        visit document_path(document)
      end

      it "is possible to delete attachments from the sidebar" do
        attachments_list.expect_attached("test.jpg")
        expect do
          attachments_list.delete("test.jpg")
          attachments_list.expect_empty
        end.to change { document.attachments.count }.by(-1)
      end
    end
  end

  context "for collaborative documents", with_settings: { real_time_text_collaboration_enabled: true } do
    include_context "with hocuspocus"

    let(:document) { create(:document, :collaborative, project:) }
    let(:editor) { FormFields::Primerized::BlockNoteEditorInput.new }
    let(:attachments_list) { Components::AttachmentsList.new }

    before do
      DocumentType.destroy_all
      visit document_path(document)
      expect(page).to have_css("op-block-note") # rubocop:disable RSpec/ExpectInHook
      expect(page).not_to have_element("opce-ckeditor-augmented-textarea") # rubocop:disable RSpec/ExpectInHook
    end

    context "with internal uploads" do
      it_behaves_like "can upload an image in BlockNote"
      it_behaves_like "with non-whitelisted file types"
      it_behaves_like "with attachments list in the sidebar"
    end

    context "with uploads to an external storage", :with_direct_uploads do
      it_behaves_like "can upload an image in BlockNote"
      it_behaves_like "with non-whitelisted file types"
      it_behaves_like "with attachments list in the sidebar"
    end
  end
end

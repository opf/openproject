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

RSpec.describe "Upload attachment to documents", :js,
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
  let!(:category) do
    create(:document_category)
  end
  let(:project) { create(:project) }
  let(:attachments) { Components::Attachments.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }
  let(:attachments_list) { Components::AttachmentsList.new }

  before do
    login_as(user)
  end

  shared_examples "can upload an image" do
    it "can upload an image" do
      visit new_project_document_path(project)

      expect(page).to have_css("#new_document", wait: 10)
      SeleniumHubWaiter.wait
      select(category.name, from: "Category")
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

        # Expect it to be present on the index page
        expect(page).to have_css(".document-category-elements--header", text: "New documentation")
        expect(page).to have_css("#content img", count: 1)
        expect(page).to have_content("Image uploaded on creation")
      end

      document = Document.last
      expect(document.title).to eq "New documentation"

      # Expect it to be present on the show page
      SeleniumHubWaiter.wait
      find(".document-category-elements--header a", text: "New documentation").click
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

    it_behaves_like "can upload an image"
  end

  context "for internal uploads", with_direct_uploads: false do
    it_behaves_like "can upload an image"
  end
end

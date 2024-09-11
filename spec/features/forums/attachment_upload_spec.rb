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

RSpec.describe "Upload attachment to forum message", :js do
  let(:forum) { create(:forum) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_messages
                                                    add_messages
                                                    edit_messages] })
  end
  let(:project) { forum.project }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }
  let(:attachments_list) { Components::AttachmentsList.new }
  let(:index_page) { Pages::Messages::Index.new(forum.project) }

  before do
    login_as(user)
  end

  it "can upload an image to new and existing messages via drag & drop" do
    index_page.visit!
    click_link forum.name

    create_page = index_page.click_create_message
    create_page.set_subject "A new message"

    # adding an image
    sleep 20
    editor.drag_attachment image_fixture.path, "Image uploaded on creation"

    editor.attachments_list.expect_attached("image.png")
    editor.wait_until_upload_progress_toaster_cleared

    click_button "Create"

    expect(page).to have_css("#content .wiki img", count: 1)
    expect(page).to have_content("Image uploaded on creation")
    attachments_list.expect_attached("image.png")

    within ".toolbar-items" do
      click_on "Edit"
    end

    find(".op-uc-figure").click
    find(".ck-widget__type-around__button_after").click

    editor.type_slowly("A spacer text")

    editor.drag_attachment image_fixture.path, "Image uploaded the second time"

    editor.attachments_list.expect_attached("image.png", count: 2)
    editor.wait_until_upload_progress_toaster_cleared

    click_button "Save"

    expect(page).to have_css("#content .wiki img", count: 2)
    expect(page).to have_content("Image uploaded on creation")
    expect(page).to have_content("Image uploaded the second time")

    attachments_list.expect_attached("image.png", count: 2)
  end

  it "can upload an image to new and existing messages via drag & drop on attachments" do
    index_page.visit!
    click_link forum.name

    create_page = index_page.click_create_message
    create_page.set_subject "A new message"

    editor.attachments_list.expect_empty

    editor.set_markdown "Some text because it's required"

    # adding an image
    editor.attachments_list.drop(image_fixture)

    editor.attachments_list.expect_attached("image.png")
    editor.wait_until_upload_progress_toaster_cleared

    click_button "Create"

    attachments_list.expect_attached("image.png")
    within ".toolbar-items" do
      click_on "Edit"
    end

    editor.attachments_list.drag_enter
    editor.attachments_list.drop(image_fixture)

    editor.attachments_list.expect_attached("image.png", count: 2)
    editor.wait_until_upload_progress_toaster_cleared

    click_button "Save"

    attachments_list.expect_attached("image.png", count: 2)
  end
end

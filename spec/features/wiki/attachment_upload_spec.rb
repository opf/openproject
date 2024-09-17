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

RSpec.describe "Upload attachment to wiki page", :js do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_wiki_pages edit_wiki_pages] })
  end
  let(:project) { create(:project) }
  let(:attachments) { Components::Attachments.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }
  let(:attachments_list) { Components::AttachmentsList.new }
  let(:wiki_page_content) { project.wiki.pages.first.text }

  before do
    login_as(user)
  end

  it "can upload an image to new and existing wiki page via drag & drop in editor" do
    visit project_wiki_path(project, "test")

    # adding an image
    editor.drag_attachment image_fixture.path, "Image uploaded the first time"

    editor.attachments_list.expect_attached("image.png")
    editor.wait_until_upload_progress_toaster_cleared

    click_on "Save"

    expect(page).to have_text("Successful creation")
    expect(page).to have_css("#content img", count: 1)
    expect(page).to have_content("Image uploaded the first time")
    attachments_list.expect_attached("image.png")

    # required sleep otherwise clicking on the Edit button doesn't do anything
    SeleniumHubWaiter.wait

    within ".toolbar-items" do
      click_on "Edit"
    end

    # Replace the image with a named attachment URL (Regression #28381)
    editor.wait_until_loaded
    editor.set_markdown "\n\nSome text\n![my-first-image](image.png)\n\nText that prevents the two images colliding"

    editor.drag_attachment image_fixture.path, "Image uploaded the second time"

    editor.attachments_list.expect_attached("image.png", count: 2)

    editor.in_editor do |container, _|
      # Expect URL is mapped to the correct URL
      expect(container).to have_css('img[src^="/api/v3/attachments/"]', count: 2)
      expect(container).to have_no_css('img[src="image.png"]')

      container.find('img[src^="/api/v3/attachments/"]', match: :first).click
    end

    handle = page.find(".ck-widget__resizer__handle-bottom-right")
    drag_by_pixel(element: handle, by_x: 0, by_y: 50)
    click_on "Save"

    expect(page).to have_text("Successful update")
    expect(page).to have_css("#content img", count: 2)
    # First figcaption is lost by having replaced the markdown
    expect(page).to have_content("Image uploaded the second time")
    attachments_list.expect_attached("image.png", count: 2)

    # Both images rendered referring to the api endpoint
    expect(page).to have_css('img[src^="/api/v3/attachments/"]', count: 2)

    # The first image is resized using width:yypx style
    expect(page).to have_css 'figure.op-uc-figure img[style*="width:"]'

    expect(wiki_page_content).to have_css '.op-uc-image[src^="/api/v3/attachments"]'
  end

  it "can upload an image to new and existing wiki page via drag & drop on attachments" do
    visit project_wiki_path(project, "test")

    editor.attachments_list.expect_empty

    # adding an image
    editor.attachments_list.drop(image_fixture.path)

    editor.attachments_list.expect_attached("image.png")
    editor.wait_until_upload_progress_toaster_cleared

    click_on "Save"

    expect(page).to have_text("Successful creation")
    attachments_list.expect_attached("image.png")

    # required sleep otherwise clicking on the Edit button doesn't do anything
    SeleniumHubWaiter.wait

    within ".toolbar-items" do
      click_on "Edit"
    end

    # adding an image
    editor.attachments_list.drag_enter
    editor.attachments_list.drop(image_fixture)

    editor.attachments_list.expect_attached("image.png", count: 2)
    editor.wait_until_upload_progress_toaster_cleared

    click_on "Save"
    expect(page).to have_text("Successful update")
    attachments_list.expect_attached("image.png", count: 2)
  end
end

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
require_relative "../../support/pages/structured_meeting/show"

RSpec.describe "Upload attachment to meetings", :js do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas] })
  end
  let(:project) { create(:project) }
  let(:attachments) { Components::Attachments.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new "#content", "opce-ckeditor-augmented-textarea" }
  let(:wiki_page_content) { project.wiki.pages.first.text }
  let(:attachment_list) { Components::AttachmentsList.new("#content") }

  let(:meeting) { create(:structured_meeting, project:) }
  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }

  before do
    login_as(user)
  end

  it "can upload an image to new and existing meeting agenda item via drag & drop in editor" do
    show_page.visit!

    click_on "Add"
    click_on "Agenda item"

    # adding an image
    editor.drag_attachment image_fixture.path, "Image uploaded the first time"

    attachment_list.expect_attached("image.png")
    editor.wait_until_upload_progress_toaster_cleared

    click_on "Save"
    expect(page).to have_css("#meeting-agenda-items-list-component img", count: 1)
    expect(page).to have_content("Image uploaded the first time")
    attachment_list.expect_attached("image.png")
  end
end

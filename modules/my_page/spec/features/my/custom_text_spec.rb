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

require_relative "../../support/pages/my/page"

RSpec.describe "Custom text widget on my page", :js do
  let(:permissions) do
    []
  end
  let(:project) { create(:project) }

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:other_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:my_page) do
    Pages::My::Page.new
  end
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new "body" }
  let(:field) { TextEditorField.new(page, "description", selector: ".inline-edit--active-field") }

  before do
    login_as user

    my_page.visit!
  end

  it "can add the widget set custom text and upload attachments" do
    my_page.add_widget(1, 1, :within, "Custom text")

    sleep(0.1)

    # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
    custom_text_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

    custom_text_widget.expect_to_span(1, 1, 2, 2)

    within custom_text_widget.area do
      find(".inplace-editing--container").click

      expect(page).to have_css(".op-uc-container_editing", wait: 10)

      field.set_value("My own little text")
      field.save!

      expect(page)
        .to have_css(".inline-edit--display-field", text: "My own little text")

      find(".inplace-editing--container").click

      field.set_value("My new text")
      field.cancel_by_click

      expect(page)
        .to have_css(".inline-edit--display-field", text: "My own little text")

      # adding an image
      find(".inplace-editing--container").click

      sleep(0.1)
    end

    # The drag_attachment is written in a way that it requires to be executed with page on body
    # so we cannot have it wrapped in the within block.
    editor.drag_attachment image_fixture.path, "Image uploaded"

    within custom_text_widget.area do
      expect(page).to have_test_selector("op-attachment-list-item", text: "image.png")
      expect(page).to have_no_css("notifications-upload-progress")

      field.save!

      expect(page)
        .to have_css("#content img", count: 1)

      expect(page)
        .not_to have_test_selector("op-attachment-list-item", text: "image.png")
    end

    # ensure no one but the page's user can see the uploaded attachment
    expect(Attachment.last.visible?(other_user))
      .to be_falsey
  end
end

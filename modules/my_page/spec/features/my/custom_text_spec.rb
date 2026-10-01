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

RSpec.describe "Custom text widget on my page",
               :js,
               :selenium do
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

  let!(:my_page_grid) do
    create(:my_page, :empty, user:)
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

    custom_text_widget.expect_to_exist

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

  # Regression test for https://community.openproject.org/wp/OP-17673
  # The pagination component replaces its clicked button with a span before the
  # click event finishes bubbling. Using composedPath() in the activate handler
  # preserves the original path so interactive elements are still detected even
  # after they are removed from the DOM.
  context "when a custom text widget contains an embedded work package table" do
    let(:permissions) { %i[view_work_packages] }
    let!(:work_package1) { create(:work_package, project:, author: user) }
    let!(:work_package2) { create(:work_package, project:, author: user) }
    let!(:my_page_grid) do
      create(:my_page, :empty, user:, row_count: 2, column_count: 2).tap do |grid|
        create(:grid_widget,
               grid:,
               identifier: "custom_text",
               start_row: 1, end_row: 2,
               start_column: 1, end_column: 2,
               options: { text: '<macro class="embedded-table" data-query-props="{}">&nbsp;</macro>' })
      end
    end

    it "does not open the editor when a pagination button in the display area is clicked",
       with_settings: { per_page_options: "1" } do
      custom_text_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within custom_text_widget.area do
        # The embedded table macro renders 1 WP per page, placing a real pagination
        # button inside the custom text display area.
        within(".op-pagination--item", text: "2") do
          click_button "2"
        end

        expect(page).to have_no_css(".op-uc-container_editing")
        expect(page)
          .to have_no_css(".subject", text: work_package1.subject)
        expect(page)
          .to have_css(".subject", text: work_package2.subject)
      end
    end
  end
end

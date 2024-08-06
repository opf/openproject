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

require_relative "../support/pages/dashboard"

RSpec.describe "Project description widget on dashboard", :js do
  let!(:type) { create(:type_task, name: "Task") }
  let!(:project) do
    create(:project, types: [type])
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards
       add_work_packages]
  end

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new "body" }
  let(:field) { TextEditorField.new(page, "description", selector: ".inline-edit--active-field") }

  before do
    login_as user
  end

  context "for a user having edit permissions" do
    before do
      dashboard_page.visit!
    end

    it "can use the wp create button macro within it" do
      dashboard_page.add_widget(1, 1, :within, "Custom text")

      sleep(0.1)

      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      custom_text_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within custom_text_widget.area do
        find(".inplace-editing--container").click
      end

      editor.insert_macro "Insert create work package button"

      expect(page).to have_css(".spot-modal")
      select "Task", from: "selected-type"
      find(".spot-modal--submit-button").click

      field.save!

      dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

      within("#content") do
        expect(page).to have_css("a[href=\"/projects/#{project.identifier}/work_packages/new?type=#{type.id}\"]")
      end
    end

    it "can add the widget set custom text and upload attachments" do
      dashboard_page.add_widget(1, 1, :within, "Custom text")

      sleep(0.1)

      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      custom_text_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within custom_text_widget.area do
        find(".inplace-editing--container").click

        field.set_value("My own little text")
        field.save!
      end

      dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

      within custom_text_widget.area do
        expect(page)
          .to have_css(".inline-edit--display-field", text: "My own little text")

        find(".inplace-editing--container").click

        field.set_value("My new text")
        field.cancel_by_click

        expect(page)
          .to have_css(".inline-edit--display-field", text: "My own little text")
      end

      dashboard_page.expect_no_toaster message: I18n.t("js.notice_successful_update")

      within custom_text_widget.area do
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
      end

      dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

      within custom_text_widget.area do
        expect(page)
          .to have_css("#content img", count: 1)

        expect(page)
          .not_to have_test_selector("op-attachment-list-item", text: "image.png")
      end
    end
  end

  context "for a user lacking edit permissions" do
    let!(:dashboard) do
      create(:dashboard_with_custom_text, project:)
    end

    let(:permissions) do
      %i[view_dashboards]
    end

    before do
      dashboard_page.visit!
    end

    it "allows reading but not editing the custom text" do
      custom_text_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within custom_text_widget.area do
        expect(page)
          .to have_content(dashboard.widgets.first.options[:text])

        expect(page)
          .to have_no_css(".inplace-editing--container")
      end
    end
  end
end

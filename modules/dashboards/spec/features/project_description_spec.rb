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
  let(:project_description) { "Some text I like to write" }
  let!(:project) do
    create(:project, description: project_description)
  end

  let(:read_only_permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:editing_permissions) do
    %i[view_dashboards
       manage_dashboards
       edit_project]
  end

  let(:read_only_user) do
    create(:user, member_with_permissions: { project => read_only_permissions })
  end

  let(:editing_user) do
    create(:user, member_with_permissions: { project => editing_permissions })
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  def add_project_description_widget
    dashboard_page.visit!
    dashboard_page.add_widget(1, 1, :within, "Project description")

    dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")
  end

  before do
    login_as current_user
    add_project_description_widget
  end

  context "without editing permissions" do
    let(:current_user) { read_only_user }

    it "can add the widget, but not edit the description" do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      description_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within(description_widget.area) do
        # The description is visible
        expect(page)
          .to have_content(project_description)

        # The description is not editable
        field = TextEditorField.new dashboard_page, "description"
        field.expect_read_only
        field.activate! expect_open: false
      end
    end
  end

  context "with editing permissions" do
    let(:current_user) { editing_user }

    it "can edit the description" do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      description_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within(description_widget.area) do
        # Open description field
        field = TextEditorField.new dashboard_page, "description"
        field.activate!
        sleep(0.1)

        # Change the value
        field.expect_value(project_description)
        field.set_value "A completely new description which is super cool."
        field.save!

        # The edit field is toggled and the value saved.
        expect(page).to have_content("A completely new description which is super cool.")
        expect(page).to have_selector(field.selector)
        expect(page).to have_no_selector(field.input_selector)
      end
    end
  end

  context "with editing and wp add permissions" do
    let!(:type) { create(:type_task, name: "Task") }
    let!(:project) do
      create(:project, types: [type])
    end

    let(:current_user) do
      create(:user, member_with_permissions: { project => editing_permissions + %i[add_work_packages] })
    end
    let(:editor) { Components::WysiwygEditor.new "body" }

    it "can create a button macro for work packages" do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      description_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      field = TextEditorField.new dashboard_page, "description"
      field.activate!

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
  end
end

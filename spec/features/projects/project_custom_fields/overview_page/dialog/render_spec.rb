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
require_relative "../shared_context"

RSpec.describe "Edit project custom fields on project overview page", :js do
  include_context "with seeded projects, members and project custom fields"

  let(:overview_page) { Pages::Projects::Show.new(project) }
  let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section_for_input_fields) }

  before do
    login_as member_with_project_attributes_edit_permissions
    overview_page.visit_page
  end

  it "opens a dialog showing inputs for project custom fields of a specific section" do
    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    dialog.expect_open
  end

  it "renders the dialog body asynchronically" do
    expect(page).to have_no_css(dialog.async_content_container_css_selector, visible: :all)

    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    expect(page).to have_css(dialog.async_content_container_css_selector, visible: :visible)
  end

  it "can be closed via close icon or cancel button" do
    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    dialog.close_via_icon

    dialog.expect_closed

    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    dialog.close_via_button

    dialog.expect_closed
  end

  it "shows only the project custom fields of the specific section within the dialog" do
    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    dialog.within_async_content(close_after_yield: true) do
      (input_fields + select_fields + multi_select_fields).each do |project_custom_field|
        if input_fields.include?(project_custom_field)
          expect(page).to have_content(project_custom_field.name)
        else
          expect(page).to have_no_content(project_custom_field.name)
        end
      end
    end

    dialog = Components::Projects::ProjectCustomFields::EditDialog.new(project, section_for_select_fields)

    overview_page.open_edit_dialog_for_section(section_for_select_fields)

    dialog.within_async_content(close_after_yield: true) do
      (input_fields + select_fields + multi_select_fields).each do |project_custom_field|
        if select_fields.include?(project_custom_field)
          expect(page).to have_content(project_custom_field.name)
        else
          expect(page).to have_no_content(project_custom_field.name)
        end
      end
    end

    dialog = Components::Projects::ProjectCustomFields::EditDialog.new(project, section_for_multi_select_fields)

    overview_page.open_edit_dialog_for_section(section_for_multi_select_fields)

    dialog.within_async_content(close_after_yield: true) do
      (input_fields + select_fields + multi_select_fields).each do |project_custom_field|
        if multi_select_fields.include?(project_custom_field)
          expect(page).to have_content(project_custom_field.name)
        else
          expect(page).to have_no_content(project_custom_field.name)
        end
      end
    end
  end

  it "shows the inputs in the correct order defined by the position of project custom field in a section" do
    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    dialog.within_async_content(close_after_yield: true) do
      containers = dialog.input_containers

      expect(containers[0].text).to include("Boolean field")
      expect(containers[1].text).to include("String field")
      expect(containers[2].text).to include("Integer field")
      expect(containers[3].text).to include("Float field")
      expect(containers[4].text).to include("Date field")
      expect(containers[5].text).to include("Link field")
      expect(containers[6].text).to include("Text field")
    end

    boolean_project_custom_field.move_to_bottom

    overview_page.open_edit_dialog_for_section(section_for_input_fields)

    dialog.within_async_content(close_after_yield: true) do
      containers = dialog.input_containers

      expect(containers[0].text).to include("String field")
      expect(containers[1].text).to include("Integer field")
      expect(containers[2].text).to include("Float field")
      expect(containers[3].text).to include("Date field")
      expect(containers[4].text).to include("Link field")
      expect(containers[5].text).to include("Text field")
      expect(containers[6].text).to include("Boolean field")
    end
  end

  context "with visibility of project custom fields" do
    let!(:section_with_invisible_fields) { create(:project_custom_field_section, name: "Section with invisible fields") }

    let!(:visible_project_custom_field) do
      create(:project_custom_field,
             name: "Normal field",
             admin_only: false,
             projects: [project],
             project_custom_field_section: section_with_invisible_fields)
    end

    let!(:invisible_project_custom_field) do
      create(:project_custom_field,
             name: "Admin only field",
             admin_only: true,
             projects: [project],
             project_custom_field_section: section_with_invisible_fields)
    end

    let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section_with_invisible_fields) }

    context "with admin permissions" do
      before do
        login_as admin
        overview_page.visit_page
      end

      it "shows all project custom fields" do
        overview_page.open_edit_dialog_for_section(section_with_invisible_fields)

        dialog.within_async_content(close_after_yield: true) do
          expect(page).to have_content("Normal field")
          expect(page).to have_content("Admin only field")
        end
      end
    end

    context "with non-admin permissions" do
      before do
        login_as member_with_project_attributes_edit_permissions
        overview_page.visit_page
      end

      it "shows only visible project custom fields" do
        overview_page.open_edit_dialog_for_section(section_with_invisible_fields)

        dialog.within_async_content(close_after_yield: true) do
          expect(page).to have_content("Normal field")
          expect(page).to have_no_content("Admin only field")
        end
      end
    end
  end
end

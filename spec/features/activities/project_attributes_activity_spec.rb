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

RSpec.describe "Project attributes activity", :js, :with_cuprite do
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages edit_work_packages],
             project2 => %i[view_work_packages edit_work_packages]
           })
  end
  let(:parent_project) { create(:project, name: "parent") }
  let(:project) { create(:project, parent: parent_project, active: false) }
  let(:project2) { create(:project, parent: parent_project, active: false) }

  let!(:list_project_custom_field) { create(:list_project_custom_field) }
  let!(:version_project_custom_field) { create(:version_project_custom_field) }
  let!(:bool_project_custom_field) { create(:boolean_project_custom_field) }
  let!(:user_project_custom_field) { create(:user_project_custom_field) }
  let!(:int_project_custom_field) { create(:integer_project_custom_field) }
  let!(:float_project_custom_field) { create(:float_project_custom_field) }
  let!(:text_project_custom_field) { create(:text_project_custom_field) }
  let!(:string_project_custom_field) { create(:string_project_custom_field) }
  let!(:date_project_custom_field) { create(:date_project_custom_field) }

  let(:old_version) do
    { project => create(:version, project:, name: "Ringbo 1.0"),
      project2 => create(:version, project: project2, name: "Ringbo 2.0") }
  end

  let(:next_version) do
    {
      project => create(:version, project:, name: "Turfu 2.0"),
      project2 => create(:version, project: project2, name: "Turfu 3.0")
    }
  end

  current_user { user }

  def generate_trackable_activity_on_project(project)
    new_project_attributes = {
      name: "a new project name-#{project.id}",
      description: "a new project description",
      status_code: "on_track",
      status_explanation: "some explanation",
      public: true,
      parent: nil,
      identifier: "a-new-project-name-#{project.id}",
      active: true,
      templated: true,
      list_project_custom_field.attribute_name => list_project_custom_field.possible_values.first.id,
      version_project_custom_field.attribute_name => [old_version[project].id, next_version[project].id],
      bool_project_custom_field.attribute_name => true,
      user_project_custom_field.attribute_name => current_user.id,
      int_project_custom_field.attribute_name => 42,
      float_project_custom_field.attribute_name => 3.14159,
      text_project_custom_field.attribute_name => "a new text CF value",
      string_project_custom_field.attribute_name => "a new string CF value",
      date_project_custom_field.attribute_name => Date.new(2023, 1, 31)
    }

    project.update!(new_project_attributes)
  end

  it "tracks the projects activities" do
    previous_project_attributes = project.attributes.dup
    generate_trackable_activity_on_project(project)

    visit project_activity_index_path(project)

    check "Project attributes"

    click_on "Apply"

    within("li.op-activity-list--item", match: :first) do
      expect(page)
        .to have_link("Project: #{project.name}")

      # own fields
      expect(page).to have_css("li", text: "Name changed from #{previous_project_attributes['name']} to #{project.name}")
      expect(page).to have_css("li", text: "Description set (Details)")
      expect(page).to have_css("li", text: "Project status set to On track")
      expect(page).to have_css("li", text: "Project status description set (Details)")
      expect(page).to have_css("li", text: "Visibility set to public")
      expect(page).to have_css("li", text: "No longer subproject of #{parent_project.name}")
      expect(page).to have_css("li", text: "Project unarchived")
      expect(page).to have_css("li", text: "Identifier changed from #{previous_project_attributes['identifier']} " \
                                           "to #{project.identifier}")
      expect(page).to have_css("li", text: "Project marked as template")

      # custom fields
      expect(page).to have_css("li", text: "#{list_project_custom_field.name} " \
                                           "set to #{project.send(list_project_custom_field.attribute_getter)}")
      expect(page).to have_css("li", text: "#{version_project_custom_field.name} " \
                                           "set to #{old_version[project].name}, #{next_version[project].name}")
      expect(page).to have_css("li", text: "#{bool_project_custom_field.name} set to Yes")
      expect(page).to have_css("li", text: "#{user_project_custom_field.name} set to #{current_user.name}")
      expect(page).to have_css("li", text: "#{int_project_custom_field.name} set to 42")
      expect(page).to have_css("li", text: "#{float_project_custom_field.name} set to 3.14159")
      expect(page).to have_css("li", text: "#{text_project_custom_field.name} set (Details)")
      expect(page).to have_css("li", text: "#{string_project_custom_field.name} set to a new string CF value")
      expect(page).to have_css("li", text: "#{date_project_custom_field.name} set to 01/31/2023")
    end
  end

  describe "the general activities page" do
    it "is expected to not show disabled attribute only on the project it was disabled on" do
      previous_project_attributes = project.attributes.dup
      generate_trackable_activity_on_project(project)
      generate_trackable_activity_on_project(project2)
      # Disable all custom fields on the project
      project.project_custom_field_project_mappings.destroy_all

      visit activity_index_path

      check "Project attributes"

      click_on "Apply"

      within("li.op-activity-list--item:nth-child(2)") do
        expect(page)
          .to have_link("Project: #{project.name}")

        # own fields
        expect(page).to have_css("li", text: "Name changed from #{previous_project_attributes['name']} to #{project.name}")
        expect(page).to have_css("li", text: "Description set (Details)")
        expect(page).to have_css("li", text: "Project status set to On track")
        expect(page).to have_css("li", text: "Project status description set (Details)")
        expect(page).to have_css("li", text: "Visibility set to public")
        expect(page).to have_css("li", text: "No longer subproject of #{parent_project.name}")
        expect(page).to have_css("li", text: "Project unarchived")
        expect(page).to have_css("li", text: "Identifier changed from #{previous_project_attributes['identifier']} " \
                                             "to #{project.identifier}")
        expect(page).to have_css("li", text: "Project marked as template")

        # custom fields
        expect(page).to have_no_css("li", text: "#{list_project_custom_field.name} " \
                                                "set to #{project.send(list_project_custom_field.attribute_getter)}")
        expect(page).to have_no_css("li", text: "#{version_project_custom_field.name} " \
                                                "set to #{old_version[project].name}, #{next_version[project].name}")
        expect(page).to have_no_css("li", text: "#{bool_project_custom_field.name} set to Yes")
        expect(page).to have_no_css("li", text: "#{user_project_custom_field.name} set to #{current_user.name}")
        expect(page).to have_no_css("li", text: "#{int_project_custom_field.name} set to 42")
        expect(page).to have_no_css("li", text: "#{float_project_custom_field.name} set to 3.14159")
        expect(page).to have_no_css("li", text: "#{text_project_custom_field.name} set to\na new text CF value")
        expect(page).to have_no_css("li", text: "#{string_project_custom_field.name} set to a new string CF value")
        expect(page).to have_no_css("li", text: "#{date_project_custom_field.name} set to 01/31/2023")
      end

      within("li.op-activity-list--item:nth-child(1)") do
        expect(page)
          .to have_link("Project: #{project2.name}")

        expect(page).to have_css("li", text: "#{int_project_custom_field.name} set to 42")
      end
    end
  end
end

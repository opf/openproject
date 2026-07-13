# frozen_string_literal: true

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

RSpec.describe "Project attributes activity", :js do
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages edit_work_packages view_project_attributes],
             project2 => %i[view_work_packages edit_work_packages view_project_attributes]
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

  describe "the project activities page" do
    let(:activity_page) { Pages::Projects::Activity.new(project) }

    let!(:project_was) { project.dup }

    before do
      generate_trackable_activity_on_project(project)
    end

    it "tracks the projects activities" do
      activity_page.visit!

      activity_page.show_details

      activity_page.within_journal(number: 1) do
        activity_page.expect_link_to_project(project)

        # own fields
        activity_page.expect_activity("Name changed from #{project_was.name} to #{project.name}")
        activity_page.expect_activity("Description set (Details)")
        activity_page.expect_activity("Status set to On track")
        activity_page.expect_activity("Status description set (Details)")
        activity_page.expect_activity("Visibility set to public")
        activity_page.expect_activity("No longer subproject of #{parent_project.name}")
        activity_page.expect_activity("Project unarchived")
        activity_page.expect_activity("Identifier changed from #{project_was.identifier} " \
                                      "to #{project.identifier}")
        activity_page.expect_activity("Project marked as template")

        # custom fields
        activity_page.expect_activity("#{list_project_custom_field.name} " \
                                      "set to #{project.send(list_project_custom_field.attribute_getter)}")
        sorted_version_names = [old_version[project], next_version[project]]
                                  .sort_by { |v| v.id.to_s }
                                  .map(&:name).join(", ")
        activity_page.expect_activity("#{version_project_custom_field.name} set to #{sorted_version_names}")
        activity_page.expect_activity("#{bool_project_custom_field.name} set to Yes")
        activity_page.expect_activity("#{user_project_custom_field.name} set to #{current_user.name}")
        activity_page.expect_activity("#{int_project_custom_field.name} set to 42")
        activity_page.expect_activity("#{float_project_custom_field.name} set to 3.14159")
        activity_page.expect_activity("#{text_project_custom_field.name} set (Details)")
        activity_page.expect_activity("#{string_project_custom_field.name} set to a new string CF value")
        activity_page.expect_activity("#{date_project_custom_field.name} set to 01/31/2023")
      end
    end
  end

  describe "custom field visibility enforcement on the project activity page" do
    let!(:string_cf) { create(:string_project_custom_field) }
    let(:cf_project) { create(:project) }
    let(:activity_page) { Pages::Projects::Activity.new(cf_project) }

    let(:user_without_cf_permission) do
      create(:user, member_with_permissions: { cf_project => %i[view_work_packages] })
    end
    let(:user_with_cf_permission) do
      create(:user, member_with_permissions: { cf_project => %i[view_work_packages view_project_attributes] })
    end

    before do
      cf_project.update!(custom_field_values: { "#{string_cf.id}": "initial" })
      cf_project.update!(custom_field_values: { "#{string_cf.id}": "changed" })
    end

    context "when the user lacks view_project_attributes" do
      current_user { user_without_cf_permission }

      it "does not show the custom field change in the activity feed" do
        activity_page.visit!
        activity_page.show_details

        expect(page).to have_no_text(string_cf.name)
      end
    end

    context "when the user has view_project_attributes" do
      current_user { user_with_cf_permission }

      it "shows the custom field change in the activity feed" do
        activity_page.visit!
        activity_page.show_details

        expect(page).to have_text(string_cf.name)
      end
    end
  end

  describe "the general activities page" do
    let(:activity_page) { Pages::Activity.new }

    let!(:project_was) { project.dup }

    before do
      generate_trackable_activity_on_project(project)
      generate_trackable_activity_on_project(project2)
      # Disable all custom fields on the project
      project.project_custom_field_project_mappings.destroy_all
    end

    it "is expected to not show disabled attribute only on the project it was disabled on" do
      activity_page.visit!

      activity_page.show_details

      activity_page.within_journal(number: 2) do
        activity_page.expect_link_to_project(project)

        # own fields
        activity_page.expect_activity("Name changed from #{project_was.name} to #{project.name}")
        activity_page.expect_activity("Description set (Details)")
        activity_page.expect_activity("Status set to On track")
        activity_page.expect_activity("Status description set (Details)")
        activity_page.expect_activity("Visibility set to public")
        activity_page.expect_activity("No longer subproject of #{parent_project.name}")
        activity_page.expect_activity("Project unarchived")
        activity_page.expect_activity("Identifier changed from #{project_was.identifier} " \
                                      "to #{project.identifier}")
        activity_page.expect_activity("Project marked as template")

        # custom fields
        activity_page.expect_no_activity("#{list_project_custom_field.name} " \
                                         "set to #{project.send(list_project_custom_field.attribute_getter)}")
        activity_page.expect_no_activity("#{version_project_custom_field.name} " \
                                         "set to #{old_version[project].name}, #{next_version[project].name}")
        activity_page.expect_no_activity("#{bool_project_custom_field.name} set to Yes")
        activity_page.expect_no_activity("#{user_project_custom_field.name} set to #{current_user.name}")
        activity_page.expect_no_activity("#{int_project_custom_field.name} set to 42")
        activity_page.expect_no_activity("#{float_project_custom_field.name} set to 3.14159")
        activity_page.expect_no_activity("#{text_project_custom_field.name} set to\na new text CF value")
        activity_page.expect_no_activity("#{string_project_custom_field.name} set to a new string CF value")
        activity_page.expect_no_activity("#{date_project_custom_field.name} set to 01/31/2023")
      end

      activity_page.within_journal(number: 1) do
        activity_page.expect_link_to_project(project2)

        activity_page.expect_activity("#{int_project_custom_field.name} set to 42")
      end
    end
  end
end

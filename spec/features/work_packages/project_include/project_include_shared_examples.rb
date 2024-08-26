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

RSpec.shared_examples "has a project include dropdown", :js, type: :feature do
  let(:dropdown) { Components::ProjectIncludeComponent.new }

  shared_let(:project) do
    create(:project, name: "Parent", enabled_module_names: enabled_modules)
  end

  shared_let(:sub_project) do
    create(:project, name: "Direct Child", parent: project, enabled_module_names: enabled_modules)
  end

  # The user will not receive a membership in this project
  # which is why it is invisible to the user.
  shared_let(:sub_sub_project_invisible) do
    create(:project, name: "Invisible Grandchild", parent: sub_project, enabled_module_names: enabled_modules)
  end

  shared_let(:sub_sub_sub_project) do
    create(:project, name: "Direct grand Grandchild", parent: sub_sub_project_invisible, enabled_module_names: enabled_modules)
  end

  shared_let(:other_project) do
    create(:project, name: "Other project", enabled_module_names: enabled_modules)
  end

  shared_let(:other_sub_project) do
    create(:project, name: "Other Child", parent: other_project, enabled_module_names: enabled_modules)
  end

  shared_let(:other_sub_sub_project) do
    create(:project, name: "First other sub sub child", parent: other_sub_project, enabled_module_names: enabled_modules)
  end

  shared_let(:another_sub_sub_project) do
    create(:project, name: "Second other sub sub child", parent: other_sub_project, enabled_module_names: enabled_modules)
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => permissions,
             sub_project => permissions,
             sub_sub_sub_project => permissions,
             other_project => permissions,
             other_sub_project => permissions,
             other_sub_sub_project => permissions,
             another_sub_sub_project => permissions
           })
  end

  shared_let(:other_user) do
    create(:user,
           firstname: "Other",
           lastname: "User",
           member_with_permissions: {
             project => permissions,
             sub_project => permissions,
             sub_sub_sub_project => permissions,
             other_project => permissions,
             other_sub_project => permissions,
             other_sub_sub_project => permissions,
             another_sub_sub_project => permissions
           })
  end

  current_user { user }

  shared_let(:type_task) { create(:type_task) }
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:closed_status) { create(:status, is_closed: true) }

  shared_let(:task) do
    create(:work_package,
           project:,
           type: type_task,
           assigned_to: user,
           start_date: Time.zone.today - 2.days,
           due_date: Time.zone.today + 1.day,
           subject: "A task for #{user.name}")
  end

  shared_let(:sub_bug) do
    create(:work_package,
           project: sub_project,
           type: type_bug,
           assigned_to: user,
           start_date: Time.zone.today - 10.days,
           due_date: Time.zone.today + 20.days,
           subject: "A bug in sub-project for #{user.name}")
  end

  shared_let(:sub_sub_bug) do
    create(:work_package,
           project: sub_sub_sub_project,
           type: type_bug,
           assigned_to: user,
           start_date: Time.zone.today - 1.day,
           due_date: Time.zone.today + 2.days,
           subject: "A bug in sub-sub-project for #{user.name}")
  end

  shared_let(:other_task) do
    create(:work_package,
           project:,
           type: type_task,
           assigned_to: other_user,
           start_date: Time.zone.today,
           due_date: Time.zone.today + 2.days,
           subject: "A task for the other user")
  end

  shared_let(:other_other_task) do
    create(:work_package,
           project: other_project,
           type: type_task,
           assigned_to: other_user,
           start_date: Time.zone.today - 2.days,
           due_date: Time.zone.today + 4.days,
           subject: "A task for the other user in other-project")
  end

  before do
    project.types << type_bug
    project.types << type_task
    sub_project.types << type_bug
    sub_project.types << type_task
    sub_sub_sub_project.types << type_bug
    sub_sub_sub_project.types << type_task

    other_project.types << type_bug
    other_project.types << type_task
    other_sub_project.types << type_bug
    other_sub_project.types << type_task
    other_sub_sub_project.types << type_bug
    other_sub_sub_project.types << type_task
    another_sub_sub_project.types << type_bug
    another_sub_sub_project.types << type_task

    login_as current_user
    work_package_view.visit!
  end

  it "can add and remove projects" do
    dropdown.expect_count 1
    dropdown.toggle!
    dropdown.expect_open

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id, true)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.toggle_include_all_subprojects

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id)
    dropdown.expect_checkbox(sub_sub_sub_project.id)

    dropdown.toggle_checkbox(other_sub_project.id)
    dropdown.toggle_checkbox(sub_sub_sub_project.id)

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id, true)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.toggle_checkbox(sub_sub_sub_project.id)

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id, true)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id)
    dropdown.expect_checkbox(sub_sub_sub_project.id)

    dropdown.click_button "Apply"
    dropdown.expect_closed
    dropdown.expect_count 2

    dropdown.toggle!

    dropdown.toggle_checkbox(sub_sub_sub_project.id)
    dropdown.click_button "Apply"
    dropdown.expect_closed
    dropdown.expect_count 3

    page.refresh

    dropdown.expect_count 3

    dropdown.toggle!

    dropdown.toggle_include_all_subprojects

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id, true)
    dropdown.expect_checkbox(other_sub_sub_project.id, true)
    dropdown.expect_checkbox(another_sub_sub_project.id, true)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id, true)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.toggle_include_all_subprojects

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id, true)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.toggle_checkbox(sub_sub_sub_project.id)

    dropdown.click_button "Apply"
    dropdown.expect_closed
    dropdown.expect_count 2
  end

  it "can clear the selection" do
    dropdown.expect_count 1
    dropdown.toggle!
    dropdown.expect_open

    dropdown.toggle_checkbox(other_project.id)
    dropdown.toggle_checkbox(project.id)
    dropdown.toggle_checkbox(sub_sub_sub_project.id)

    dropdown.expect_checkbox(other_project.id, true)
    dropdown.expect_checkbox(other_sub_project.id, true)
    dropdown.expect_checkbox(other_sub_sub_project.id, true)
    dropdown.expect_checkbox(another_sub_sub_project.id, true)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id, true)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.click_button "Apply"
    dropdown.expect_closed
    dropdown.expect_count 2

    dropdown.toggle!

    dropdown.click_button "Clear selection"

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id, true)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.toggle_include_all_subprojects

    dropdown.toggle_checkbox(other_sub_project.id)
    dropdown.toggle_checkbox(sub_sub_sub_project.id)

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id, true)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id)
    dropdown.expect_checkbox(sub_sub_sub_project.id, true)

    dropdown.click_button "Apply"
    dropdown.expect_closed
    dropdown.expect_count 3

    dropdown.toggle!

    dropdown.click_button "Clear selection"

    dropdown.expect_checkbox(other_project.id)
    dropdown.expect_checkbox(other_sub_project.id)
    dropdown.expect_checkbox(other_sub_sub_project.id)
    dropdown.expect_checkbox(another_sub_sub_project.id)
    dropdown.expect_checkbox(project.id, true)
    dropdown.expect_checkbox(sub_project.id)
    dropdown.expect_checkbox(sub_sub_sub_project.id)

    dropdown.click_button "Apply"
    dropdown.expect_closed
    dropdown.expect_count 1
  end

  it "filter projects in the list" do
    dropdown.expect_count 1
    dropdown.toggle!
    dropdown.expect_open

    retry_block do
      dropdown.search sub_sub_sub_project.name

      dropdown.expect_no_checkbox(other_project.id)
      dropdown.expect_no_checkbox(other_sub_project.id)
      dropdown.expect_no_checkbox(other_sub_sub_project.id)
      dropdown.expect_no_checkbox(another_sub_sub_project.id)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(sub_project.id, true)
      dropdown.expect_checkbox(sub_sub_sub_project.id, true)
    end

    retry_block do
      dropdown.search other_project.name

      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_no_checkbox(other_sub_project.id)
      dropdown.expect_no_checkbox(other_sub_sub_project.id)
      dropdown.expect_no_checkbox(another_sub_sub_project.id)
      dropdown.expect_no_checkbox(project.id)
      dropdown.expect_no_checkbox(sub_project.id)
      dropdown.expect_no_checkbox(sub_sub_sub_project.id)
    end

    retry_block do
      dropdown.search ""

      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_checkbox(other_sub_project.id)
      dropdown.expect_checkbox(other_sub_sub_project.id)
      dropdown.expect_checkbox(another_sub_sub_project.id)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(sub_project.id, true)
      dropdown.expect_checkbox(sub_sub_sub_project.id, true)
    end

    dropdown.toggle_checkbox(other_sub_sub_project.id)

    retry_block do
      dropdown.set_filter_selected true

      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_checkbox(other_sub_project.id)
      dropdown.expect_checkbox(other_sub_sub_project.id, true)
      dropdown.expect_no_checkbox(another_sub_sub_project.id)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(sub_project.id, true)
      dropdown.expect_checkbox(sub_sub_sub_project.id, true)
    end

    dropdown.toggle_checkbox(other_project.id)

    retry_block do
      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_checkbox(other_sub_project.id)
      dropdown.expect_checkbox(other_sub_sub_project.id, true)
    end

    retry_block do
      dropdown.set_filter_selected false
      dropdown.toggle_checkbox(other_project.id)

      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(other_sub_project.id, true)
      dropdown.expect_checkbox(other_sub_sub_project.id, true)
      dropdown.expect_checkbox(another_sub_sub_project.id, true)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(sub_project.id, true)
      dropdown.expect_checkbox(sub_sub_sub_project.id, true)
    end

    dropdown.toggle_include_all_subprojects

    retry_block do
      dropdown.set_filter_selected true

      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(other_sub_project.id)
      dropdown.expect_checkbox(other_sub_sub_project.id, true)
      dropdown.expect_no_checkbox(another_sub_sub_project.id)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_no_checkbox(sub_project.id)
      dropdown.expect_no_checkbox(sub_sub_sub_project.id)
    end

    retry_block do
      dropdown.search other_project.name

      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_no_checkbox(other_sub_project.id)
      dropdown.expect_no_checkbox(other_sub_sub_project.id)
      dropdown.expect_no_checkbox(another_sub_sub_project.id)
      dropdown.expect_no_checkbox(project.id)
      dropdown.expect_no_checkbox(sub_project.id)
      dropdown.expect_no_checkbox(sub_sub_sub_project.id)
    end

    retry_block do
      dropdown.search ""

      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_no_checkbox(other_sub_project.id)
      dropdown.expect_no_checkbox(other_sub_sub_project.id)
      dropdown.expect_no_checkbox(another_sub_sub_project.id)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_no_checkbox(sub_project.id)
      dropdown.expect_no_checkbox(sub_sub_sub_project.id)
    end

    retry_block do
      dropdown.set_filter_selected false

      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(other_sub_project.id)
      dropdown.expect_checkbox(other_sub_sub_project.id, true)
      dropdown.expect_checkbox(another_sub_sub_project.id)
      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_sub_project.id)
    end
  end

  it "keeps working even when there are no results (regression #42908)" do
    dropdown.expect_count 1
    dropdown.toggle!
    dropdown.expect_open
    dropdown.search "Nonexistent"
    expect(page).to have_no_css("[data-test-selector='op-project-include--loading']")
  end
end

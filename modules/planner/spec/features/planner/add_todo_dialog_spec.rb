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

RSpec.describe "Adding a to-do in My planner", :js, with_flag: { planner: true } do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let!(:task_type) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }
  let!(:role) do
    create(:project_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR +
             %i[view_work_packages add_work_packages manage_work_package_relations])
  end
  let(:team_project) { create(:project) }
  let(:user) do
    create(:user, member_with_permissions: { team_project => %i[view_work_packages manage_work_package_relations] })
  end
  let!(:work_package) { create(:work_package, project: team_project, subject: "Wiki permissions") }

  current_user { user }

  before { visit planner_path }

  it "focuses the to-do and links the picked work package" do
    page.find("a[data-controller='async-dialog']", text: "Add to-do").click

    expect(page).to have_field("To-do", focused: true)

    fill_in "To-do", with: "Ask Maya about"
    select_autocomplete(page.find_test_selector("planner-work-package-autocompleter"), query: "Wiki permissions")
    page.find_test_selector("planner-add-todo-submit").click

    expect(page).to have_no_css("##{Planner::AddTodoDialogComponent::DIALOG_ID}")
    expect(page).to have_test_selector("planner-reference", text: "Wiki permissions")
    expect(WorkPackage.find_by(subject: "Ask Maya about ##{work_package.display_id}")).to be_present
  end
end

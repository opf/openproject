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

RSpec.describe "Subproject creation", :js do
  let(:parent_field) { FormFields::SelectFormField.new :parent }
  let(:add_subproject_role) { create(:project_role, permissions: %i[edit_project add_subprojects]) }
  let(:view_project_role) { create(:project_role, permissions: %i[edit_project]) }
  let!(:default_project_role) { create(:project_creator_role) }
  let!(:parent_project) do
    create(:project,
           name: "Foo project",
           members: { current_user => add_subproject_role })
  end
  let!(:other_project) do
    create(:project,
           name: "Other project",
           members: { current_user => view_project_role })
  end

  current_user do
    create(:user)
  end

  before do
    allow(Setting).to receive(:new_project_user_role_id).and_return(default_project_role.id.to_s)
    visit project_settings_general_path(parent_project)
  end

  it "can create a subproject" do
    wait_for_turbo { click_on "New subproject" }
    expect(page).to have_heading "New project"

    # Step 1: Select workspace type (blank project)
    click_on "Continue"

    # Step 2: Fill in project details
    fill_in "Name", with: "Foo child"

    expect(page).to have_no_field "Subproject of"

    click_on "Complete"

    expect_and_dismiss_flash type: :success, message: "Successful creation."

    expect(page).to have_current_path /\/projects\/foo-child\/?/

    child = Project.last
    expect(child.identifier).to eq "foo-child"
    expect(child.parent).to eq parent_project
  end
end

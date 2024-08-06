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

RSpec.describe "Subproject creation", :js, :with_cuprite do
  let(:name_field) { FormFields::InputFormField.new :name }
  let(:parent_field) { FormFields::SelectFormField.new :parent }
  let(:add_subproject_role) { create(:project_role, permissions: %i[edit_project add_subprojects]) }
  let(:view_project_role) { create(:project_role, permissions: %i[edit_project]) }
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
    visit project_settings_general_path(parent_project)
  end

  it "can create a subproject" do
    click_link "Subproject"

    name_field.set_value "Foo child"
    parent_field.expect_required
    # The other project is not a valid parent since the user is lacking
    # the add_subproject permission therein.
    parent_field.expect_no_option(other_project.name)
    parent_field.expect_selected parent_project.name

    click_button "Save"

    expect(page).to have_current_path /\/projects\/foo-child\/?/

    child = Project.last
    expect(child.identifier).to eq "foo-child"
    expect(child.parent).to eq parent_project
  end
end

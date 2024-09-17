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

RSpec.describe "Projects", "work package type mgmt", :js, :with_cuprite do # rubocop:disable RSpec/SortMetadata
  current_user { create(:user, member_with_permissions: { project => %i[edit_project manage_types] }) }

  let(:phase_type)     { create(:type, name: "Phase", is_default: true) }
  let(:milestone_type) { create(:type, name: "Milestone", is_default: false) }
  let!(:project) { create(:project, name: "Foo project", types: [phase_type, milestone_type]) }

  it "have the correct types checked for the project's types" do
    visit projects_path
    click_on "Foo project"
    click_on "Project settings"
    click_on "Work package types"

    expect(find_field("Phase", visible: false)["checked"])
      .to be_truthy

    expect(find_field("Milestone", visible: false)["checked"])
      .to be_truthy

    # Disable a type
    find_field("Milestone", visible: false).click

    click_button "Save"

    expect(find_field("Milestone", visible: false)["checked"])
      .to be_falsey
  end
end

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

RSpec.describe "List custom fields edit", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
    visit custom_fields_path(tab: :TimeEntryCustomField)
  end

  it "can create and edit list custom fields (#37654)" do
    # Create CF
    click_on "Create a new custom field"

    wait_for_reload

    fill_in "custom_field_name", with: "My List CF"
    select "List", from: "custom_field_field_format"

    expect(page).to have_field("custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_custom_options_attributes_0_value", with: "A"

    click_on "Save"

    # Expect correct values
    cf = CustomField.last
    expect(cf.name).to eq("My List CF")
    expect(cf.possible_values.map(&:value)).to eq %w(A)

    # Edit again
    find("a", text: "My List CF").click

    expect(page).to have_field("custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_custom_options_attributes_0_value", with: "B"

    click_on "Save"

    # Expect correct values again
    cf = CustomField.last
    expect(cf.name).to eq("My List CF")
    expect(cf.possible_values.map(&:value)).to eq %w(B)
  end
end

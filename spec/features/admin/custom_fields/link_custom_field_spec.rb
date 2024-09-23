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

RSpec.describe "Link custom fields edit", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let(:cf_page) { Pages::CustomFields.new }

  before do
    login_as(admin)
    visit custom_fields_path
  end

  it "can create and edit user custom fields" do
    # Create CF
    click_link "Create a new custom field"

    wait_for_reload

    fill_in "custom_field_name", with: "My Link CF"
    select "Link (URL)", from: "custom_field_field_format"

    expect(page).to have_no_field("custom_field_custom_options_attributes_0_value")

    click_on "Save"

    # Expect field to be created
    cf = CustomField.last
    expect(cf.name).to eq("My Link CF")
    expect(cf.field_format).to eq "link"

    # Edit again
    find("a", text: "My Link CF").click

    expect(page).to have_no_field("custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_name", with: "My Link CF (edited)"

    click_on "Save"

    # Expect field to be saved
    cf = CustomField.last
    expect(cf.name).to eq("My Link CF (edited)")
  end
end

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

RSpec.describe "Multi-value custom fields creation", :js do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
    visit custom_fields_path
  end

  it "can create and reorder custom field list values" do
    # Create CF
    click_on "Create a new custom field"

    SeleniumHubWaiter.wait
    fill_in "custom_field_name", with: "My List CF"
    select "List", from: "custom_field_field_format"

    expect(page).to have_css("input#custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_custom_options_attributes_0_value", with: "A"

    # Add new row
    page.find_test_selector("add-custom-option").click
    SeleniumHubWaiter.wait
    expect(page).to have_css("input#custom_field_custom_options_attributes_1_value")
    fill_in "custom_field_custom_options_attributes_1_value", with: "B"

    # Add new row
    page.find_test_selector("add-custom-option").click
    SeleniumHubWaiter.wait
    expect(page).to have_css("input#custom_field_custom_options_attributes_2_value")
    fill_in "custom_field_custom_options_attributes_2_value", with: "C"

    click_on "Save"

    # Edit again
    SeleniumHubWaiter.wait
    page.find("a", text: "My List CF").click
    expect(page).to have_css("input#custom_field_custom_options_attributes_0_value[value=A]")
    expect(page).to have_css("input#custom_field_custom_options_attributes_1_value[value=B]")
    expect(page).to have_css("input#custom_field_custom_options_attributes_2_value[value=C]")

    # Expect correct values
    cf = CustomField.last
    expect(cf.name).to eq("My List CF")
    expect(cf.possible_values.map(&:value)).to eq %w(A B C)

    # Drag and drop

    # We need to hack a target for where to drag the row to
    page.execute_script <<-JS
      const container = document.querySelector('[data-test-selector="dragula-container"]');
      const element = document.createElement('tr')
      element.classList.add('__drag_and_drop_end_of_list');
      element.innerHTML = '<td colspan="4" style="height: 100px"></td>';
      container.insertAdjacentElement('beforeend', element);
    JS

    rows = page.all("tr.custom-option-row")
    expect(rows.length).to eq(3)
    drag_n_drop_element from: rows[0].find(".dragula-handle"), to: page.find(".__drag_and_drop_end_of_list")

    sleep 1

    page.execute_script <<-JS
      document.querySelector('.__drag_and_drop_end_of_list').remove();
    JS

    click_on "Save"
    # Edit again
    expect(page).to have_field("custom_field_custom_options_attributes_0_value", with: "B")
    expect(page).to have_field("custom_field_custom_options_attributes_1_value", with: "C")
    expect(page).to have_field("custom_field_custom_options_attributes_2_value", with: "A")

    cf.reload
    expect(cf.name).to eq("My List CF")
    expect(cf.possible_values.map(&:value)).to eq %w(B C A)
  end
end

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
require_relative "../shared_custom_field_expectations"

RSpec.describe "List custom fields edit", :js do
  shared_let(:admin) { create(:admin) }

  let(:index_cf_page) { Pages::CustomFields::Index.new }
  let(:new_cf_page) { Pages::CustomFields::New.new }

  current_user { admin }

  before do
    index_cf_page.visit_page("Spent time")
  end

  it "can create and edit list custom fields (#37654)" do
    index_cf_page.expect_none_listed
    # Create CF
    index_cf_page.click_to_create_new_custom_field("List")

    fill_in "custom_field_name", with: "My List CF"

    click_on "Save"

    index_cf_page.expect_flash(message: "Successful creation.")

    click_link "Items"

    expect(page).to have_field("custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_custom_options_attributes_0_value", with: "A"

    click_on "Save"
    wait_for_network_idle

    # Expect correct values
    cf = CustomField.last
    expect(cf.name).to eq("My List CF")
    expect(cf.possible_values.map(&:value)).to eq %w(A)

    # Edit again
    expect(page).to have_field("custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_custom_options_attributes_0_value", with: "B"

    click_on "Save"
    wait_for_network_idle

    index_cf_page.expect_and_dismiss_flash(message: "Successful update.")

    # Expect correct values again
    cf = CustomField.last
    expect(cf.name).to eq("My List CF")
    expect(cf.possible_values.map(&:value)).to eq %w(B)
  end

  it_behaves_like "list custom fields", "Spent time"

  it_behaves_like "expected fields for the custom field's format", "Spent time", "List"
end

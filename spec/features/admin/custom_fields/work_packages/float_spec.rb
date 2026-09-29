# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "custom fields", :js do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }

  current_user { user }

  before do
    cf_page.visit!
  end

  describe "creating a new float custom field" do
    it "creates a new float custom field" do
      cf_page.click_to_create_new_custom_field("Float")

      cf_page.set_name "New Field"
      cf_page.set_default_value "20.34"
      click_on "Save"

      cf_page.expect_and_dismiss_flash(message: "Successful creation.")

      expect(page).to have_text("New Field")
    end

    it "round trips decimal value bounds" do
      cf_page.click_to_create_new_custom_field("Float")

      cf_page.set_name "Bounded Float"
      cf_page.set_min_value "0.1234"
      cf_page.set_max_value "10.25"
      click_on "Save"

      cf_page.expect_and_dismiss_flash(message: "Successful creation.")

      custom_field = CustomField.find_by!(name: "Bounded Float")
      expect(custom_field.min_value).to eq 0.1234
      expect(custom_field.max_value).to eq 10.25

      visit edit_custom_field_path(custom_field)

      expect(page).to have_field("custom_field[min_value]", with: "0.1234")
      expect(page).to have_field("custom_field[max_value]", with: "10.25")
    end

    it "rejects a minimum above the maximum" do
      cf_page.click_to_create_new_custom_field("Float")

      cf_page.set_name "Bad Bounds"
      cf_page.set_min_value "10"
      cf_page.set_max_value "1"
      click_on "Save"

      expect(page).to have_text("Minimum value must be smaller than or equal to maximum value.")
      expect(CustomField.find_by(name: "Bad Bounds")).to be_nil
    end
  end
end

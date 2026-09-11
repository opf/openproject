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
  shared_let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }

  current_user { user }

  before do
    cf_page.visit!
    cf_page.click_to_create_new_custom_field("Boolean")
  end

  describe "available fields" do
    it "shows all form elements" do
      expect(cf_page).to have_field("Name")
      expect(cf_page).to have_field("Default value")
      expect(cf_page).to have_field("Used as a filter")
    end
  end

  describe "creating a new boolean custom field" do
    it "creates a new bool custom field" do
      cf_page.set_name "New Field"
      click_on "Save"

      cf_page.expect_and_dismiss_flash(message: "Successful creation.")

      expect(page).to have_text("New Field")
    end
  end
end

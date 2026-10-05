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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin screens" do # rubocop:disable RSpec/DescribeClass
  context "as administrator" do
    current_user { create(:admin) }

    it "lists, creates and edits a screen" do
      screen = create(:create_screen, name: "Bug create")
      visit admin_screens_path
      expect(page).to have_text("Bug create")
      expect(page).to have_no_link("Delete")

      visit new_admin_screen_path
      fill_in "screen_name", with: "Story create"
      select "Create", from: "screen[screen_type]"
      click_button "Save"
      expect(page).to have_text("Successful creation.")

      visit edit_admin_screen_path(screen)
      fill_in "screen_name", with: "Renamed"
      click_button "Save"
      expect(screen.reload.name).to eq("Renamed")
    end
  end

  context "as a non administrator" do
    current_user { create(:user) }

    it "is forbidden" do
      visit admin_screens_path
      expect(page).to have_text("You are not authorized")
    end
  end
end

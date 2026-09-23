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

RSpec.describe "work package list custom fields", :js do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }

  before do
    login_as user
  end

  describe "editing an existing list custom field" do
    let!(:custom_field) do
      create(
        :list_wp_custom_field,
        name: "Platform",
        possible_values: %w[Playstation Xbox Nintendo PC]
      )
    end

    before do
      cf_page.visit!
      wait_for_reload

      click_on custom_field.name
      wait_for_reload

      click_link "Items"
      wait_for_reload
    end

    it "shows the correct breadcrumbs" do
      page.within_test_selector("custom-fields--page-header") do
        expect(page).to have_css(".breadcrumb-item", text: "Work packages")
        expect(page).to have_css(".breadcrumb-item.breadcrumb-item-selected", text: "Platform")
      end
    end
  end
end

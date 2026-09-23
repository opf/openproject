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

RSpec.describe "User custom fields edit", :js do
  shared_let(:admin) { create(:admin) }
  let(:index_cf_page) { Pages::CustomFields::Index.new }
  let(:new_cf_page) { Pages::CustomFields::New.new }

  current_user { admin }

  before do
    index_cf_page.visit!
  end

  it "can create and edit user custom fields (#48725)" do
    # Create CF
    index_cf_page.click_to_create_new_custom_field("User")

    fill_in "Name", with: "My User CF"

    click_on "Save"

    new_cf_page.expect_and_dismiss_flash(message: "Successful creation.")

    cf = CustomField.last
    expect(page).to have_current_path(edit_custom_field_path(cf))

    # Edit again
    fill_in "Name", with: "My User CF (edited)"

    click_on "Save"

    new_cf_page.expect_and_dismiss_flash(message: "Successful update.")

    # Expect field to be saved
    cf.reload

    expect(page).to have_css(".PageHeader-title", text: "My User CF (edited)")
    expect(cf.name).to eq("My User CF (edited)")
  end
end

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

RSpec.describe "Admin screen schemes" do # rubocop:disable RSpec/DescribeClass
  current_user { create(:admin) }

  let!(:type) { create(:type, name: "Bug") }
  let!(:create_screen) { create(:create_screen, name: "Bug create") }

  it "edits a scheme through the type matrix" do
    scheme = create(:screen_scheme, name: "Dev")
    visit edit_admin_screen_scheme_path(scheme)

    select "Bug create", from: "scheme[types][#{type.id}][create_screen_id]"
    click_button "Save"

    expect(page).to have_text("Successful update.")
    expect(scheme.reload.item_for(type.id).create_screen).to eq(create_screen)
  end

  it "is forbidden for non administrators" do
    scheme = create(:screen_scheme)
    login_as(create(:user))
    visit edit_admin_screen_scheme_path(scheme)
    expect(page).to have_text("You are not authorized")
  end
end

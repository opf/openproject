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

RSpec.describe "group show page" do
  let!(:member) { create(:user) }
  let!(:group) { create(:group, lastname: "Bob's Team", members: [member]) }

  before do
    login_as current_user
  end

  context "as an admin" do
    shared_let(:admin) { create(:admin) }
    let(:current_user) { admin }

    it "I can visit the group page" do
      visit show_group_path(group)
      expect(page).to have_test_selector("groups--title", text: "Bob's Team")
      expect(page).to have_test_selector("groups--edit-group-button", text: "Edit")
      expect(page).to have_css("li", text: member.name)
    end
  end

  context "as a regular user" do
    let(:current_user) { create(:user) }

    it "I can visit the group page" do
      visit show_group_path(group)
      expect(page).to have_test_selector("groups--title", text: "Bob's Team")
      expect(page).not_to have_test_selector("groups--edit-group-button")
      expect(page).to have_no_css("li", text: member.name)
    end
  end
end

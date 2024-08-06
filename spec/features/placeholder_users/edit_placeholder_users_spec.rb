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

RSpec.describe "edit placeholder users", :js do
  shared_let(:placeholder_user) { create(:placeholder_user, name: "UX Developer") }

  shared_examples "placeholders edit flow" do
    it "can edit name" do
      visit edit_placeholder_user_path(placeholder_user)

      expect(page).to have_css "#placeholder_user_name"

      fill_in "placeholder_user[name]", with: "NewName", fill_options: { clear: :backspace }

      click_on "Save"

      expect(page).to have_css(".op-toast.-success", text: "Successful update.")

      placeholder_user.reload

      expect(placeholder_user.name).to eq "NewName"
    end
  end

  context "as admin" do
    current_user { create(:admin) }

    it_behaves_like "placeholders edit flow"
  end

  context "as user with global permission" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }

    it_behaves_like "placeholders edit flow"
  end

  context "as user without global permission" do
    current_user { create(:user) }

    it "returns an error" do
      visit edit_placeholder_user_path(placeholder_user)
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end

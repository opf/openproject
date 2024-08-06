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

RSpec.describe "create placeholder users", :selenium do
  let(:new_placeholder_user_page) { Pages::NewPlaceholderUser.new }

  shared_examples_for "placeholders creation flow" do
    context "with enterprise", with_ee: %i[placeholder_users] do
      it "creates the placeholder user" do
        visit new_placeholder_user_path

        new_placeholder_user_page.fill_in! name: "UX Designer"

        new_placeholder_user_page.submit!

        expect(page).to have_css(".op-toast", text: "Successful creation.")

        new_placeholder_user = PlaceholderUser.order(Arel.sql("id DESC")).first

        expect(current_path).to eql(edit_placeholder_user_path(new_placeholder_user.id))
      end
    end

    context "without enterprise" do
      it "creates the placeholder user" do
        visit new_placeholder_user_path

        new_placeholder_user_page.fill_in! name: "UX Designer"
        new_placeholder_user_page.submit!

        expect(page).to have_text "is only available in the OpenProject Enterprise edition"
      end
    end
  end

  context "as admin" do
    current_user { create(:admin) }

    it_behaves_like "placeholders creation flow"
  end

  context "as user with global permission" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }

    it_behaves_like "placeholders creation flow"
  end

  context "as user without global permission" do
    current_user { create(:user) }

    it "returns an error" do
      visit new_placeholder_user_path
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end

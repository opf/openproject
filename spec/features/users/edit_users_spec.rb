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

RSpec.describe "edit users", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let(:current_user) { admin }
  let(:user) { create(:user, mail: "foo@example.com") }

  let!(:auth_source) { create(:ldap_auth_source) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  def auth_select
    find "select#user_ldap_auth_source_id"
  end

  def user_password
    find "input#user_password"
  end

  context "with internal authentication" do
    before do
      visit edit_user_path(user)
    end

    it "shows internal authentication being selected including password settings" do
      expect(auth_select.value).to eq "" # selected internal
      expect(user_password).to be_visible
    end

    it "hides password settings when switching to an LDAP auth source" do
      auth_select.select auth_source.name

      expect(page).to have_no_field("#user_password")
    end
  end

  context "with external authentication" do
    before do
      user.ldap_auth_source = auth_source
      user.save!

      visit edit_user_path(user)
    end

    it "shows external authentication being selected and no password settings" do
      expect(auth_select.value).to eq auth_source.id.to_s
      expect(page).to have_no_field("#user_password")
    end

    it "shows password settings when switching back to internal authentication" do
      auth_select.select I18n.t("label_internal")

      expect(user_password).to be_visible
    end
  end

  def have_visible_tab(label)
    have_css(".tabnav-tab", text: label)
  end

  context "as admin" do
    it "can edit attributes of an admin user" do
      another_admin = create(:admin)
      visit edit_user_path(another_admin)

      expect(page).to have_visible_tab("General")
    end
  end

  context "as global user" do
    shared_let(:global_manage_user) { create(:user, global_permissions: %i[manage_user create_user]) }
    let(:current_user) { global_manage_user }

    it "can too edit the user" do
      visit edit_user_path(user)

      expect(page).to have_visible_tab("General")

      expect(page).to have_no_css(".admin-overview-menu-item", text: "Overview")
      expect(page).to have_no_css(".users-and-permissions-menu-item", text: "Users and permissions")
      expect(page).to have_css(".users-menu-item.selected", text: "Users")

      expect(page).to have_select(id: "user_ldap_auth_source_id")
      expect(page).to have_no_field "#user_password"

      expect(page).to have_css "#user_login"
      expect(page).to have_css "#user_firstname"
      expect(page).to have_css "#user_lastname"
      expect(page).to have_css "#user_mail"

      firstname_field = find_by_id("user_firstname")
      firstname_field.value.length.times do
        firstname_field.send_keys(:backspace)
      end
      firstname_field.set "NewName"
      select auth_source.name, from: "user[ldap_auth_source_id]"

      click_button "Save"

      expect(page).to have_css(".op-toast.-success", text: "Successful update.")

      user.reload

      expect(user.firstname).to eq "NewName"
      expect(user.ldap_auth_source).to eq auth_source
    end

    it "can reinvite the user" do
      visit edit_user_path(user)

      click_on "Send invitation"

      expect(page).to have_css(".op-toast.-success", text: "An invitation has been sent to foo@example.com")
    end

    it "can not edit attributes of an admin user" do
      visit edit_user_path(admin)

      expect(page).to have_visible_tab("Projects")
      expect(page).not_to have_visible_tab("General")
    end
  end
end

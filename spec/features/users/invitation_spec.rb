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

RSpec.describe "invitations", :js do
  let(:user) { create(:invited_user, mail: "holly@openproject.com") }

  shared_examples "resending invitations" do |redirect_to_edit_page: true|
    it "resends the invitation" do
      login_with current_user.login, "adminADMIN!"

      visit user_path(user)
      click_on I18n.t(:label_send_invitation)
      expect(page).to have_current_path redirect_to_edit_page ? edit_user_path(user) : user_path(user)
      expect(page).to have_text "An invitation has been sent to holly@openproject.com."

      # Logout admin
      visit signout_path

      # Visit invitation with wrong token
      visit account_activate_path(token: "some invalid value")
      expect(page).to have_text "Invalid activation token"

      # Visit invitation link with correct token
      visit account_activate_path(token: Token::Invitation.last.value)

      expect(page).to have_test_selector("registration-form")
    end
  end

  context "as admin" do
    shared_let(:admin) { create(:admin) }
    let(:current_user) { admin }

    include_examples "resending invitations"
  end

  context "as as user with global user_create permission" do
    shared_let(:global_create_user) { create(:user, global_permissions: %i[view_all_principals create_user]) }
    let(:current_user) { global_create_user }

    include_examples "resending invitations", redirect_to_edit_page: false
  end

  context "as as user with global user_create and manage_user permission" do
    shared_let(:global_create_user) { create(:user, global_permissions: %i[view_all_principals create_user manage_user]) }
    let(:current_user) { global_create_user }

    include_examples "resending invitations", redirect_to_edit_page: true
  end

  describe "activating the invitation" do
    let(:token) { Token::Invitation.create!(user:) }

    before do
      visit account_activate_path(token: token.value)
    end

    context "when users may change their email", with_settings: { user_can_change_email: true } do
      it "allows choosing a different email" do
        expect(page).to have_field("user[mail]", with: "holly@openproject.com", readonly: false)
      end
    end

    context "when users may not change their email", with_settings: { user_can_change_email: false } do
      it "pins the account to the invited email" do
        expect(page).to have_field("user[mail]", with: "holly@openproject.com", readonly: true)
      end
    end
  end
end

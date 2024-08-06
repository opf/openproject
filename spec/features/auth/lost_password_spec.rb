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

RSpec.describe "Lost password" do
  let!(:user) { create(:user) }
  let(:new_password) { "new_PassW0rd!" }

  it "allows logging in after having lost the password" do
    visit account_lost_password_path

    # shows same flash for invalid and existing users
    fill_in "mail", with: "invalid mail"
    click_on "Submit"

    expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_account_lost_email_sent))

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to be 0

    fill_in "mail", with: user.mail
    click_on "Submit"
    expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_account_lost_email_sent))

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to be 1

    # mimic the user clicking on the link in the mail
    token = Token::Recovery.first
    visit account_lost_password_path(token: token.value)

    fill_in "New password", with: new_password
    fill_in "Confirmation", with: new_password

    click_button "Save"

    expect(page).to have_css(".op-toast.-info", text: I18n.t(:notice_account_password_updated))

    login_with user.login, new_password

    expect(page)
      .to have_current_path(my_page_path)
  end

  context "when user has an auth source" do
    let!(:ldap_auth_source) { create(:ldap_auth_source, name: "Foo") }
    let!(:user) { create(:user, ldap_auth_source:) }

    it "sends an email with external auth info" do
      visit account_lost_password_path

      # shows same flash for invalid and existing users
      fill_in "mail", with: user.mail
      click_on "Submit"

      expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_account_lost_email_sent))

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to be 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq I18n.t("mail_password_change_not_possible.title")
      expect(mail.body.parts.first.body.to_s).to include "Foo"
    end
  end

  context "when user has identity_url" do
    let!(:user) { create(:user, identity_url: "saml:foobar") }

    it "sends an email with external auth info" do
      visit account_lost_password_path

      # shows same flash for invalid and existing users
      fill_in "mail", with: user.mail
      click_on "Submit"

      expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_account_lost_email_sent))

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to be 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq I18n.t("mail_password_change_not_possible.title")
      expect(mail.body.parts.first.body.to_s).to include "Saml"
    end
  end
end

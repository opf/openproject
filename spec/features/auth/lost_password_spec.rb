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

RSpec.describe "Lost password" do
  let!(:user) { create(:user) }
  let(:new_password) { "new_PassW0rd!" }

  it "allows logging in after having lost the password" do
    visit account_lost_password_path

    # shows same flash for invalid and existing users
    fill_in "mail", with: "invalid mail"
    click_on "Submit"

    expect_flash(message: I18n.t(:notice_account_lost_email_sent))

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to be 0

    fill_in "mail", with: user.mail
    click_on "Submit"
    expect_flash(message: I18n.t(:notice_account_lost_email_sent))

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to be 1
    mail = ActionMailer::Base.deliveries.first
    expect(mail.subject).to eq I18n.t("mail_subject_lost_password", value: Setting.app_title)

    # mimic the user clicking on the link in the mail
    token = Token::Recovery.first
    mail_body = mail.body.parts.find { |p| p.mime_type == "text/html" }.body.to_s
    mail_document = Capybara::Node::Simple.new(mail_body)
    visit mail_document.find("a")["href"]

    fill_in "New password", with: new_password
    fill_in "Confirmation", with: new_password

    click_button "Save"

    expect_flash(type: :info, message: I18n.t(:notice_account_password_updated))

    login_with user.login, new_password

    expect(page)
      .to have_current_path(home_path)
  end

  context "when user has an auth source" do
    let!(:ldap_auth_source) { create(:ldap_auth_source, name: "Foo") }
    let!(:user) { create(:user, ldap_auth_source:) }

    it "sends an email with external auth info" do
      visit account_lost_password_path

      # shows same flash for invalid and existing users
      fill_in "mail", with: user.mail
      click_on "Submit"

      expect_flash(message: I18n.t(:notice_account_lost_email_sent))

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to be 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq I18n.t("mail_password_change_not_possible.title")
      expect(mail.body.parts.first.body.to_s).to include "Foo"
    end
  end

  context "when user only authenticates via SSO" do
    let!(:provider) { create(:saml_provider, slug: "saml", display_name: "The SAML provider") }
    let!(:user) { create(:user, :passwordless, authentication_provider: provider) }

    it "sends an email with external auth info" do
      visit account_lost_password_path

      # shows same flash for invalid and existing users
      fill_in "mail", with: user.mail
      click_on "Submit"

      expect_flash(message: I18n.t(:notice_account_lost_email_sent))

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to be 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq I18n.t("mail_password_change_not_possible.title")
      expect(mail.body.parts.first.body.to_s).to include "(The SAML provider)"
    end
  end

  context "when authenticates via password & SSO" do
    let!(:provider) { create(:saml_provider, slug: "saml", display_name: "The SAML provider") }
    let!(:user) { create(:user, authentication_provider: provider) }

    it "sends an email with external auth info" do
      visit account_lost_password_path

      # shows same flash for invalid and existing users
      fill_in "mail", with: user.mail
      click_on "Submit"

      expect_flash(message: I18n.t(:notice_account_lost_email_sent))

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to be 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq I18n.t("mail_subject_lost_password", value: Setting.app_title)
    end
  end
end

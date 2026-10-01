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

RSpec.describe "Authentication Settings", :js do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  describe "login settings" do
    let(:login_page) { Pages::Admin::Authentication::Login.new }

    before do
      login_page.visit!
    end

    it "allows changing autologin options" do
      select "90 days", from: "Autologin"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_select "Autologin", selected: "90 days"

      select "disabled", from: "Autologin"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_select "Autologin", selected: "disabled"
    end

    it "allows changing session expiration options" do
      expect(login_page).to have_unchecked_field "Session expires"
      expect(login_page).to have_no_field "Session expiration time after inactivity"

      check "Session expires"
      expect(login_page).to have_field "Session expiration time after inactivity"

      fill_in "Session expiration time after inactivity", with: "30"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_checked_field "Session expires"
      expect(login_page).to have_field "Session expiration time after inactivity",
                                       with: "30",
                                       accessible_description: "minutes"

      uncheck "Session expires"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_unchecked_field "Session expires"
      expect(login_page).to have_no_field "Session expiration time after inactivity"
    end

    it "allows changing logging options" do
      expect(login_page).to have_unchecked_field "Log user login, name, and mail address for all requests"

      check "Log user login, name, and mail address for all requests"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_checked_field "Log user login, name, and mail address for all requests"

      uncheck "Log user login, name, and mail address for all requests"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_unchecked_field "Log user login, name, and mail address for all requests"
    end

    it "allows changing login redirect options" do
      expect(login_page).to have_field "First login redirect", with: ""
      expect(login_page).to have_field "After login redirect", with: ""

      fill_in "First login redirect", with: "/my/page"
      fill_in "After login redirect", with: "/projects/awesome-project"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_field "First login redirect", with: "/my/page"
      expect(login_page).to have_field "After login redirect", with: "/projects/awesome-project"

      fill_in "First login redirect", with: "/projects/failing-project"

      login_page.save
      Setting.clear_cache
      login_page.reload!

      expect(login_page).to have_field "First login redirect", with: "/projects/failing-project"
      expect(login_page).to have_field "After login redirect", with: "/projects/awesome-project"
    end
  end

  describe "passwords settings" do
    let(:passwords_page) { Pages::Admin::Authentication::Passwords.new }

    before do
      Setting.password_active_rules = %w[lowercase uppercase numeric special]
      passwords_page.visit!
    end

    it "allows unchecking all password requirements" do
      OpenProject::Passwords::Evaluator.known_rules.each do |rule|
        passwords_page.expect_rule_checked(rule)
        uncheck I18n.t("label_password_rule_#{rule}")
      end

      passwords_page.save
      Setting.clear_cache
      passwords_page.reload!

      OpenProject::Passwords::Evaluator.known_rules.each do |rule|
        passwords_page.expect_rule_unchecked(rule)
      end
    end
  end

  describe "self registration settings" do
    let(:registration_page) { Pages::Admin::Authentication::Registration.new }

    it "allows changing self registration options" do
      registration_page.visit!

      choose I18n.t(:setting_self_registration_disabled)
      registration_page.expect_hidden_unsupervised_self_registration_warning
      registration_page.save
      Setting.clear_cache
      expect(Setting::SelfRegistration.disabled?).to be(true)
      registration_page.expect_self_registration_selected(:disabled)
      registration_page.expect_hidden_unsupervised_self_registration_warning

      choose I18n.t(:setting_self_registration_activation_by_email)
      registration_page.expect_visible_unsupervised_self_registration_warning
      registration_page.save
      Setting.clear_cache
      expect(Setting::SelfRegistration.by_email?).to be(true)
      registration_page.expect_self_registration_selected(:activation_by_email)
      registration_page.expect_visible_unsupervised_self_registration_warning

      choose I18n.t(:setting_self_registration_manual_activation)
      registration_page.expect_hidden_unsupervised_self_registration_warning
      registration_page.save
      Setting.clear_cache
      expect(Setting::SelfRegistration.manual?).to be(true)
      registration_page.expect_self_registration_selected(:manual_activation)
      registration_page.expect_hidden_unsupervised_self_registration_warning

      choose I18n.t(:setting_self_registration_automatic_activation)
      registration_page.expect_visible_unsupervised_self_registration_warning
      registration_page.save
      Setting.clear_cache
      expect(Setting::SelfRegistration.automatic?).to be(true)
      registration_page.expect_self_registration_selected(:automatic_activation)
      registration_page.expect_visible_unsupervised_self_registration_warning
    end
  end
end

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Authentication Stages', type: :feature, js: true do
  let(:language) { 'en' }
  let(:user_password) { 'bob' * 4 }
  let(:user) do
    FactoryGirl.create(
      :user,
      admin: true,
      force_password_change: false,
      first_login: false,
      login: 'bob',
      mail: 'bob@example.com',
      firstname: 'Bo',
      lastname: 'B',
      language: language,
      password: user_password,
      password_confirmation: user_password
    )
  end

  before do
    Setting.consent_required = consent_required
  end

  def expect_logged_in
    visit my_account_path
    expect(page).to have_selector('.form--field-container', text: user.login)
  end

  def expect_not_logged_in
    visit my_account_path
    expect(page).to have_no_selector('.form--field-container', text: user.login)
  end


  context 'when disabled' do
    let(:consent_required) { false }
    it 'should not show consent' do
      login_with user.login, user_password
      expect(page).to have_no_selector('.account-consent')
      expect_logged_in
    end
  end

  context 'when enabled, but no consent info', with_settings: { consent_info: {} } do
    let(:consent_required) { true }
    it 'should not show consent' do
      expect(Rails.logger)
        .to receive(:error)
        .at_least(:once)
        .with('Instance is configured to require consent, but no consent_info has been set.')
      login_with user.login, user_password
      expect(page).to have_no_selector('.account-consent')
      expect_logged_in
    end
  end
  context 'when enabled, localized consent exists',
          with_settings: { consent_info: { de: 'h1. Einwilligung', en: 'h1. Consent header!'} } do
    let(:consent_required) { true }
    let(:language) { 'de' }

    it 'should show localized consent' do
      login_with user.login, user_password

      expect(page).to have_selector('.account-consent')
      expect(page).to have_selector('h1', text: 'Einwilligung')
    end
  end

  context 'when enabled, but consent exists', with_settings: { consent_info: { en: 'h1. Consent header!'} } do
    let(:consent_required) { true }
    it 'should show consent' do
      expect(Setting.consent_time).to be_blank
      login_with user.login, user_password

      expect(page).to have_selector('.account-consent')
      expect(page).to have_selector('h1', text: 'Consent header')

      # Can't submit without confirmation
      click_on I18n.t(:button_continue)

      expect(page).to have_selector('.account-consent')
      expect(page).to have_selector('h1', text: 'Consent header')

      # Confirm consent
      check 'consent_check'
      click_on I18n.t(:button_continue)

      expect_logged_in

      # Should have set consent date
      user.reload
      expect(user.consented_at).to be_present

      # Log in again should not show consent
      visit signout_path
      login_with user.login, user_password
      expect_logged_in

      # Update consent date
      visit settings_path(tab: 'users')
      find("#toggle_consent_time").set(true)

      within '#tab-content-users' do
        click_on 'Save'
      end
      expect(page).to have_selector('.flash.notice')

      Setting.clear_cache
      expect(Setting.consent_time).to be_present

      # Will now have to consent again after logout
      visit signout_path
      login_with user.login, user_password

      # Confirm consent
      check 'consent_check'
      click_on I18n.t(:button_continue)
      expect_logged_in

      # Should now have consented for this date
      visit signout_path
      login_with user.login, user_password
      expect_logged_in
    end

    it 'should require consent from newly registered users' do
      login_as user

      # Invite new user
      visit new_user_path
      fill_in 'user_mail', with: 'foo@example.org'
      fill_in 'user_firstname', with: 'First'
      fill_in 'user_lastname', with: 'Last'

      click_on I18n.t(:button_create)

      # Get invitation token and log in as that user
      visit signout_path
      token = Token::Invitation.last.value
      visit "/account/activate?token=#{token}"

      expect(page).to have_selector('h1', text: 'Consent header')
      # Cannot create without accepting
      fill_in 'user_password', with: user_password
      fill_in 'user_password_confirmation', with: user_password
      click_on I18n.t(:button_create)

      expect(page).to have_selector('h1', text: 'Consent header')
      check 'consent_check'
      click_on I18n.t(:button_create)

      expect(page).to have_selector('.flash.notice')
      expect_logged_in
    end

    context 'with contact mail address', with_settings: { consent_decline_mail: 'foo@example.org' } do
      it 'shows that address to users when declining' do
        login_with user.login, user_password

        expect(page).to have_selector('.account-consent')
        expect(page).to have_selector('h1', text: 'Consent header')

        # Decline the consent
        click_on I18n.t(:button_decline)

        expect(page).to have_selector('.flash.error', text: 'foo@example.org')
      end
    end
  end
end

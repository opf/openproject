require_relative '../../spec_helper'
require_relative '../shared_2fa_examples'

describe 'Login with 2FA remember cookie', type: :feature,
         with_2fa_ee: true,
         with_config: {:'2fa' => {active_strategies: [:developer], allow_remember_for_days: 30 }},
         js: true do
  let(:user_password) {'bob!' * 4}
  let(:user) do
    FactoryBot.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
    )
  end
  let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, active: true, default: true}

  def login_with_cookie
    page.driver.browser.manage.delete_all_cookies

    sms_token = nil
    allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
        .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end

    first_login_step

    expect(page).to have_selector('input#remember_me')
    check 'remember_me'

    two_factor_step sms_token
    expect_logged_in
  end

  def expect_no_autologin
    first_login_step

    expect(page).to have_selector('input#otp')
    expect_not_logged_in
  end

  context 'not enabled',

          with_config: {:'2fa' => {active_strategies: [:developer], allow_remember_for_days: 0 }} do
    it 'does not show the save form' do
      first_login_step
      expect(page).to have_no_selector('input#remember_me')
    end
  end

  context 'user has no remember cookie' do
    it 'can remove the autologin cookie after login' do
      login_with_cookie
      visit my_2fa_devices_path

      find('.two-factor-authentication--remove-remember-cookie-link').click
      expect(page).to have_selector('.flash.notice')
      expect(page).to have_no_selector('.two-factor-authentication--remove-remember-cookie-link')

      # Log out and in again
      visit '/logout'
      expect_no_autologin
    end

    it 'allows to save a cookie on the login step for subsequent steps' do
      login_with_cookie

      # Log out and in again
      visit '/logout'
      first_login_step

      # Expect no OTP required
      expect_logged_in

      # Expire token
      token = ::TwoFactorAuthentication::RememberedAuthToken.find_by!(user: user)
      expect(token).not_to be_expired
      token.update_columns(expires_on: 1.day.ago, created_on: 31.days.ago)

      # Log out and in again
      visit '/logout'
      expect_no_autologin

      # Login to save cookie again
      login_with_cookie

      # Disable functionality
      allow(::OpenProject::TwoFactorAuthentication::TokenStrategyManager)
        .to receive(:allow_remember_for_days)
        .and_return(0)

      # Log out and in again
      visit '/logout'
      expect_no_autologin

      # Enable functionality
      allow(::OpenProject::TwoFactorAuthentication::TokenStrategyManager)
          .to receive(:allow_remember_for_days)
          .and_return(1)

      login_with_cookie
    end
  end
end


require_relative '../../spec_helper'
require_relative '../shared_2fa_examples'

describe 'Login with 2FA backup code', with_2fa_ee: true, type: :feature,
         with_config: {:'2fa' => {active_strategies: [:developer]}},
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

  context 'user has no backup code' do
    it 'does not show the backup code link' do
      first_login_step

      # Open other options
      find('#toggle_resend_form').click
      expect(page).to have_no_selector('a', text: I18n.t('two_factor_authentication.backup_codes.enter_backup_code_title'))
    end
  end

  context 'user has backup codes' do
    let!(:valid_backup_codes) { ::TwoFactorAuthentication::BackupCode.regenerate! user }

    it 'allows entering a backup code' do
      expect(valid_backup_codes.length).to eq(10)

      first_login_step

      expect(page).to have_selector('#toggle_resend_form', wait: 10)

      # Wait for the frontend to be loaded and initialized
      # On downstream configurations, this might take longer than marionette selecting the element
      expect_angular_frontend_initialized

      # Open other options
      # This may fail on the first request when the assets aren't ready yet
      retry_block do
        find('#toggle_resend_form').click
        find('a', text: I18n.t('two_factor_authentication.login.enter_backup_code_title'), wait: 10).click
      end

      expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.login.enter_backup_code_title'))
      fill_in 'backup_code', with: 'whatever'
      click_on 'Submit'

      # Expect failure
      expect(page).to have_selector('.flash.error', text: I18n.t('two_factor_authentication.error_invalid_backup_code'))
      expect(current_path).to eql signin_path

      # Try again!
      first_login_step
      find('#toggle_resend_form').click
      find('a', text: I18n.t('two_factor_authentication.login.enter_backup_code_title')).click

      expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.login.enter_backup_code_title'))
      fill_in 'backup_code', with: valid_backup_codes.first
      click_on 'Submit'

      expect_logged_in
    end
  end
end


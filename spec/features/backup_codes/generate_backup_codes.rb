require_relative '../../spec_helper'
require_relative '../shared_2fa_examples'

describe 'Generate 2FA backup codes', with_2fa_ee: true, type: :feature,
         with_config: {:'2fa' => {active_strategies: [:developer]}},
         js: true do
  let(:user_password) {'bob!' * 4}
  let(:user) do
    FactoryGirl.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
    )
  end
  let(:dialog) { ::Components::PasswordConfirmationDialog.new }

  before do
    login_as user
  end

  it 'allows generating backup codes' do
    visit my_2fa_devices_path

    # Log token for next access
    backup_codes = nil
    expect(::TwoFactorAuthentication::BackupCode)
        .to receive(:regenerate!)
        .and_wrap_original do |m, user|
      backup_codes = m.call(user)
    end

    # Confirm with wrong password
    expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.backup_codes.plural'))
    click_on I18n.t('two_factor_authentication.backup_codes.generate.title')
    dialog.confirm_flow_with 'wrong_password', should_fail: true

    # Confirm with correc password
    expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.backup_codes.plural'))
    click_on I18n.t('two_factor_authentication.backup_codes.generate.title')
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_selector('.notification-box.-warning')
    backup_codes.each do |code|
      expect(page).to have_selector('.two-factor-authentication--backup-codes li', text: code)
    end
  end
end


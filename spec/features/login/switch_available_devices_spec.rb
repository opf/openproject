require_relative '../../spec_helper'
require_relative '../shared_2fa_examples'

describe 'Login by switching 2FA device', with_2fa_ee: true, type: :feature,
         with_config: {:'2fa' => {active_strategies: [:developer, :totp]}},
         js: true do
  let(:user_password) {'bob!' * 4}
  let(:user) do
    FactoryGirl.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
    )
  end

  context 'with two default device' do
    let!(:device) { FactoryGirl.create :two_factor_authentication_device_sms, user: user, active: true, default: true}
    let!(:device2) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, active: true, default: false}

    it 'requests a 2FA and allows switching' do
      first_login_step

      expect(page).to have_selector('input#otp')

      # Toggle device to TOTP
      find('#toggle_resend_form').click
      find(".button--link[value='#{device2.redacted_identifier}']").click

      expect(page).to have_selector('input#otp')
      expect(page).to have_selector('#submit_otp p', text: device2.redacted_identifier)

      two_factor_step(device2.totp.now)
      expect_logged_in
    end
  end
end


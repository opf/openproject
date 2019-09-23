require_relative '../../spec_helper'
require_relative '../shared_2fa_examples'

describe 'Login with enforced 2FA', with_2fa_ee: true, type: :feature,
         with_config: {:'2fa' => {active_strategies: [:developer], enforced: true }},
         js: true do
  let(:user_password) {'bob!' * 4}
  let(:user) do
    FactoryBot.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
    )
  end

  context 'with a default device' do
    let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, active: true, default: true}

    it 'requests a 2FA' do
      sms_token = nil
      allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
          .to receive(:create_mobile_otp).and_wrap_original do |m|
        sms_token = m.call
      end

      first_login_step
      two_factor_step(sms_token)
      expect_logged_in
    end

    it 'returns to 2FA page if invalid' do
      first_login_step
      two_factor_step('whatever')

      expect(page).to have_selector('.flash.error', text: I18n.t(:notice_account_otp_invalid))
      expect(current_path).to eql signin_path
    end
  end

  context 'without a device' do
    before do
      first_login_step
    end

    it_behaves_like 'create enforced sms device'
  end
end


require_relative '../spec_helper'
require_relative './shared_2fa_examples'

describe 'activating an invited account',
         with_2fa_ee: true,
         type: :feature,
         js: true,
         with_config: {:'2fa' => {active_strategies: [:developer]}} do
  let(:user) {
    user = FactoryBot.build :user, first_login: true
    UserInvitation.invite_user! user

    user
  }
  let(:token) {Token::Invitation.find_by(user_id: user.id)}

  def activate!
    visit url_for(controller: :account,
                  action: :activate,
                  token: token.value,
                  only_path: true)

    expect(current_path).to eql account_register_path

    fill_in I18n.t('attributes.password'), with: 'Password1234'
    fill_in I18n.t('activerecord.attributes.user.password_confirmation'), with: 'Password1234'

    click_button I18n.t(:button_create)
  end

  context 'when not enforced and no device present' do
    it 'redirects to active' do
      activate!

      visit my_account_path
      expect(page).to have_selector('.form--field-container', text: user.login)
    end
  end

  context 'when not enforced, but device present' do
    let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, default: true}

    it 'requests a OTP' do
      sms_token = nil
      allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
          .to receive(:create_mobile_otp).and_wrap_original do |m|
        sms_token = m.call
      end

      activate!

      expect(page).to have_selector('.flash.notice', text: 'Developer strategy generated the following one-time password:')

      fill_in I18n.t(:field_otp), with: sms_token
      click_button I18n.t(:button_login)

      visit my_account_path
      expect(page).to have_selector('.form--field-container', text: user.login)
    end

    it 'handles faulty user input on two factor authentication' do
      activate!

      expect(page).to have_selector('.flash.notice', text: 'Developer strategy generated the following one-time password:')

      fill_in I18n.t(:field_otp), with: 'asdf' # faulty token
      click_button I18n.t(:button_login)

      expect(current_path).to eql signin_path
      expect(page).to have_content(I18n.t(:notice_account_otp_invalid))
    end
  end

  context 'when enforced', with_config: {:'2fa' => {active_strategies: [:developer], enforced: true}} do
    before do
      activate!
    end

    it_behaves_like 'create enforced sms device'
  end
end

require_relative '../spec_helper'

describe 'Password change with OTP', with_2fa_ee: true, type: :feature,
         with_config: {:'2fa' => {active_strategies: [:developer]}},
         js: true do
  let(:user_password) {'bob' * 4}
  let(:new_user_password) {'obb' * 4}
  let(:user) do
    FactoryBot.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
    )
  end
  let(:expected_path_after_login) {my_page_path}


  def handle_password_change(requires_otp: true)
    visit signin_path
    within('#login-form') do
      fill_in('username', with: user.login)
      fill_in('password', with: user_password)
      click_link_or_button I18n.t(:button_login)
    end

    sms_token = nil
    allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
        .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end

    expect(page).to have_selector('h2', text: I18n.t(:button_change_password))
    within('#content') do
      fill_in('password', with: user_password)
      fill_in('new_password', with: new_user_password)
      fill_in('new_password_confirmation', with: new_user_password)
      click_link_or_button I18n.t(:button_save)
    end

    if requires_otp
      expect(page).to have_selector('input#otp')
      fill_in 'otp', with: sms_token
      click_button I18n.t(:button_login)
    end

    expect(current_path).to eql expected_path_after_login
  end

  context 'when password is expired',
          with_settings: {password_days_valid: 7} do

    before do
      user
    end

    context 'when device present' do
      let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, default: true }

      it 'requires the password change after expired' do
        expect(user.current_password).not_to be_expired

        Timecop.travel(2.weeks.from_now) do
          expect(user.current_password).to be_expired
          handle_password_change

          user.reload
          expect(user.current_password).not_to be_expired
        end
      end
    end

    context 'when no device present' do
      let!(:device) { nil }

      it 'requires the password change after expired' do
        expect(user.current_password).not_to be_expired

        Timecop.travel(2.weeks.from_now) do
          expect(user.current_password).to be_expired
          handle_password_change(requires_otp: false)

          user.reload
          expect(user.current_password).not_to be_expired
        end
      end
    end
  end

  context 'when force password change is set' do
    let(:user_password) {'bob' * 4}
    let(:new_user_password) {'obb' * 4}
    let(:user) do
      FactoryBot.create(:user,
                         force_password_change: true,
                         first_login: true,
                         login: 'bob',
                         password: user_password,
                         password_confirmation: user_password,
      )
    end
    let(:expected_path_after_login) {home_path}

    before do
      user
    end

    context 'when device present' do
      let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, default: true }

      it 'requires the password change' do
        handle_password_change
      end
    end

    context 'when no device present' do
      let!(:device) { nil }

      it 'requires the password change without otp' do
        handle_password_change(requires_otp: false)
      end
    end
  end
end


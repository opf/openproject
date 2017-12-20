require_relative '../spec_helper'

describe 'My Account 2FA configuration', with_2fa_ee: true, type: :feature,
         with_config: {:'2fa' => {active_strategies: [:developer, :totp]}},
         js: true do
  let(:dialog) { ::Components::PasswordConfirmationDialog.new }
  let(:user_password) {'bob!' * 4}
  let(:user) do
    FactoryGirl.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
    )
  end

  before do
    login_as user
  end

  it 'allows 2FA device management' do

    # Visit empty index
    visit my_2fa_devices_path
    expect(page).to have_selector('.generic-table--empty-row', text: I18n.t('two_factor_authentication.devices.not_existing'))
    expect(page).to have_selector('.on-off-status.-disabled')

    # Visit inline create
    find('.wp-inline-create--add-link').click
    expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.devices.add_new'))
    expect(current_path).to eq new_my_2fa_device_path

    # Select SMS
    find('.mobile-otp-new-device-sms .button').click

    # Try to save with invalid phone number
    fill_in 'device_phone_number', with: 'invalid!'
    click_button I18n.t(:button_continue)

    # Enter valid phone number
    expect(page).to have_selector('#errorExplanation', text: 'Phone number must be of format +XX XXXXXXXXX')
    fill_in 'device_phone_number', with: '+49 123456789'
    click_button I18n.t(:button_continue)

    # Fill in wrong token
    fill_in 'otp', with: 'whatever'

    # Log token for next access
    sms_token = nil
    allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
        .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end

    click_button I18n.t(:button_continue)

    expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.devices.confirm_device'))
    expect(page).to have_selector('input#otp')
    expect(page).to have_selector('.flash.error', text: I18n.t('two_factor_authentication.devices.registration_failed_token_invalid'))

    # Fill in correct token
    fill_in 'otp', with: sms_token
    click_button I18n.t(:button_continue)

    # Assert that it exists and is default
    expect(page).to have_selector('.mobile-otp--two-factor-device-row td', text: 'Mobile phone (bob) (+49 123456789)')
    expect(page).to have_selector('.mobile-otp--two-factor-device-row td .icon-yes', count: 2)
    expect(page).to have_selector('.on-off-status.-enabled')

    # Create another one as totp
    # Visit create button
    visit my_2fa_devices_path
    find('.toolbar-item .button', text: '2FA device').click
    expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.devices.add_new'))
    expect(current_path).to eq new_my_2fa_device_path

    # Select totp
    find('.mobile-otp-new-device-totp .button').click

    # Change identifier
    fill_in 'device_identifier', with: 'custom identifier'
    click_button I18n.t(:button_continue)

    # Confirm token
    expect(page).to have_selector('h2', text: I18n.t('two_factor_authentication.devices.confirm_device'))
    expect(page).to have_selector('input#otp')

    device = user.otp_devices.order(:id).last
    expect(device.identifier).to eq 'custom identifier'
    expect(device.default).to be_falsey
    expect(device.active).to be_falsey

    fill_in 'otp', with: device.totp.now
    click_button I18n.t(:button_continue)

    expect(page).to have_selector('.mobile-otp--two-factor-device-row', count: 2)
    rows = page.all('.mobile-otp--two-factor-device-row')
    expect(rows[0]).to have_selector('.mobile-otp--two-factor-device-row td .icon-yes', count: 2)
    expect(rows[1]).to have_selector('.mobile-otp--two-factor-device-row td', text: 'custom identifier')
    expect(rows[1]).to have_selector('.mobile-otp--two-factor-device-row td .icon-yes', count: 1)

    device.reload
    expect(device.active).to be_truthy
    expect(device.default).to be_falsey

    # Make the second one the default
    # Confirm the password wrongly
    find('.two-factor--mark-default-button').click
    dialog.confirm_flow_with 'wrong_password', should_fail: true

    # Confirm again
    find('.two-factor--mark-default-button').click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_selector('.mobile-otp--two-factor-device-row', count: 2)
    rows = page.all('.mobile-otp--two-factor-device-row')
    expect(rows[0]).to have_selector('.mobile-otp--two-factor-device-row td .icon-yes', count: 1)
    expect(rows[1]).to have_selector('.mobile-otp--two-factor-device-row td .icon-yes', count: 2)

    device.reload
    expect(device.default).to be_truthy

    # Delete the sms device
    rows[0].find('.two-factor--delete-button').click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_selector('.mobile-otp--two-factor-device-row', count: 1)
    expect(page).to have_selector('.on-off-status.-enabled')
    expect(user.otp_devices.count).to eq 1

    # Delete the totp device
    find('.two-factor--delete-button').click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_selector('.generic-table--empty-row', text: I18n.t('two_factor_authentication.devices.not_existing'))
    expect(page).to have_selector('.on-off-status.-disabled')
    expect(user.otp_devices.count).to eq 0
  end
end


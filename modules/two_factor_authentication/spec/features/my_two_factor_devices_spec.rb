require_relative "../spec_helper"

RSpec.describe "My Account 2FA configuration", :js, with_settings: {
  plugin_openproject_two_factor_authentication: { "active_strategies" => %i[developer totp] }
} do
  let(:dialog) { Components::PasswordConfirmationDialog.new }
  let(:user_password) { "boB!4" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  before do
    login_as user
  end

  it "allows 2FA device management" do
    # Visit empty index
    visit my_2fa_devices_path
    expect(page).to have_css(".generic-table--empty-row", text: I18n.t("two_factor_authentication.devices.not_existing"))
    expect(page).to have_css(".on-off-status.-disabled")

    # Select SMS
    menu_button = find_test_selector("two_factor_authentication_devices_button")
    menu_button.click
    wait_for_network_idle if using_cuprite?
    expect(page).to have_test_selector("two_factor_authentication_devices_sms")
    sms_menu_item = find_test_selector("two_factor_authentication_devices_sms")
    sms_menu_item.click

    # Try to save with invalid phone number
    fill_in "device_phone_number", with: "invalid!"
    click_button I18n.t(:button_continue)

    # Enter valid phone number
    expect(page).to have_css("#errorExplanation", text: "Phone number must be of format +XX XXXXXXXXX")
    fill_in "device_phone_number", with: "+49 123456789"
    click_button I18n.t(:button_continue)

    # Fill in wrong token
    fill_in "otp", with: "whatever"

    # Log token for next access
    sms_token = nil
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
      .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end
    # rubocop:enable RSpec/AnyInstance

    click_button I18n.t(:button_continue)

    expect(page).to have_css("h2", text: I18n.t("two_factor_authentication.devices.confirm_device"))
    expect(page).to have_css("input#otp")
    expect(page).to have_css(".op-toast.-error",
                             text: I18n.t("two_factor_authentication.devices.registration_failed_token_invalid"))

    # Fill in correct token
    fill_in "otp", with: sms_token
    click_button I18n.t(:button_continue)

    # Assert that it exists and is default
    expect(page).to have_css(".mobile-otp--two-factor-device-row td", text: "Mobile phone (bob) (+49 123456789)")
    expect(page).to have_css(".mobile-otp--two-factor-device-row td .icon-yes", count: 2)
    expect(page).to have_css(".on-off-status.-enabled")

    # Create another one as totp
    visit my_2fa_devices_path
    menu_button = find_test_selector("two_factor_authentication_devices_button")
    menu_button.click
    wait_for_network_idle if using_cuprite?
    expect(page).to have_test_selector("two_factor_authentication_devices_totp")
    # Select totp
    totp_menu_item = find_test_selector("two_factor_authentication_devices_totp")
    totp_menu_item.click
    expect(page).to have_test_selector("two_factor_authentication_new_device_header_title",
                                       text: I18n.t("two_factor_authentication.devices.add_new"))
    expect(page).to have_current_path new_my_2fa_device_path, ignore_query: true

    # Change identifier
    fill_in "device_identifier", with: "custom identifier"
    click_button I18n.t(:button_continue)

    # Confirm token
    expect(page).to have_css("h2", text: I18n.t("two_factor_authentication.devices.confirm_device"))
    expect(page).to have_css("input#otp")

    device = user.otp_devices.order(:id).last
    expect(device.identifier).to eq "custom identifier"
    expect(device.default).to be_falsey
    expect(device.active).to be_falsey

    fill_in "otp", with: device.totp.now
    click_button I18n.t(:button_continue)

    expect(page).to have_css(".mobile-otp--two-factor-device-row", count: 2)
    rows = page.all(".mobile-otp--two-factor-device-row")
    expect(rows[0]).to have_css(".mobile-otp--two-factor-device-row td .icon-yes", count: 2)
    expect(rows[1]).to have_css(".mobile-otp--two-factor-device-row td", text: "custom identifier")
    expect(rows[1]).to have_css(".mobile-otp--two-factor-device-row td .icon-yes", count: 1)

    device.reload
    expect(device.active).to be_truthy
    expect(device.default).to be_falsey

    # Make the second one the default
    # Confirm the password wrongly
    find(".two-factor--mark-default-button").click
    dialog.confirm_flow_with "wrong_password", should_fail: true

    # Confirm again
    find(".two-factor--mark-default-button").click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_css(".mobile-otp--two-factor-device-row", count: 2)
    rows = page.all(".mobile-otp--two-factor-device-row")
    expect(rows[0]).to have_css(".mobile-otp--two-factor-device-row td .icon-yes", count: 1)
    expect(rows[1]).to have_css(".mobile-otp--two-factor-device-row td .icon-yes", count: 2)

    device.reload
    expect(device.default).to be_truthy

    # Delete the sms device
    rows[0].find(".two-factor--delete-button").click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_css(".mobile-otp--two-factor-device-row", count: 1)
    expect(page).to have_css(".on-off-status.-enabled")
    expect(user.otp_devices.count).to eq 1

    # Delete the totp device
    find(".two-factor--delete-button").click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_css(".generic-table--empty-row", text: I18n.t("two_factor_authentication.devices.not_existing"))
    expect(page).to have_css(".on-off-status.-disabled")
    expect(user.otp_devices.count).to eq 0
  end

  context "when a device has been registered already" do
    let!(:device) { create(:two_factor_authentication_device_totp, user:) }

    it "loads the page correctly (Regression #41719)" do
      visit my_2fa_devices_path

      expect(page).to have_content device.identifier
    end
  end
end

def first_login_step
  visit signin_path
  within("#login-form") do
    fill_in("username", with: user.login)
    fill_in("password", with: user_password)
    click_link_or_button I18n.t(:button_login)
  end
  wait_for_network_idle
end

def two_factor_step(token)
  expect(page).to have_css("input#otp")
  fill_in "otp", with: token
  click_button I18n.t(:button_login)
  wait_for_network_idle
end

def expect_logged_in
  visit my_account_path
  wait_for_network_idle
  expect(page).to have_css(".form--field-container", text: user.login)
end

def expect_not_logged_in
  visit my_account_path
  expect(page).to have_no_css(".form--field-container", text: user.login)
end

RSpec.shared_examples "login without 2FA" do
  it "logs in the user without any active devices" do
    first_login_step
    expect_logged_in
  end
end

RSpec.shared_examples "create enforced sms device" do
  it do
    expect_flash(type: :info,
                 message: I18n.t("two_factor_authentication.forced_registration.required_to_add_device"))

    SeleniumHubWaiter.wait
    # Create SMS device
    find(".mobile-otp-new-device-sms .button--tiny").click
    SeleniumHubWaiter.wait
    fill_in "device_phone_number", with: "invalid"
    click_on "Continue"
    wait_for_network_idle

    # Expect error on invalid phone
    expect_flash(type: :error, message: "Phone number must be of format +XX XXXXXXXXX")

    SeleniumHubWaiter.wait
    fill_in "device_phone_number", with: "+49 123456789"
    click_on "Continue"
    wait_for_network_idle

    # Confirm page
    expect(page).to have_css("h2", text: I18n.t("two_factor_authentication.devices.confirm_device"))
    expect(page).to have_css("input#otp")

    # Fill in wrong token
    fill_in "otp", with: "whatever"

    # Log token for next access
    sms_token = nil
    allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
      .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end

    click_button I18n.t(:button_continue)

    expect(page).to have_css("h2", text: I18n.t("two_factor_authentication.devices.confirm_device"))
    expect(page).to have_css("input#otp")
    expect_flash(type: :error, message: I18n.t("two_factor_authentication.devices.registration_failed_token_invalid"))

    SeleniumHubWaiter.wait
    # Fill in wrong token
    fill_in "otp", with: sms_token
    click_button I18n.t(:button_continue)

    # Expected logged in after correct registration
    expect_logged_in
  end
end

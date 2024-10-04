require_relative "../spec_helper"

RSpec.describe "Admin 2FA management", :js, with_settings: {
  plugin_openproject_two_factor_authentication: { "active_strategies" => %i[developer totp] }
} do
  let(:dialog) { Components::PasswordConfirmationDialog.new }
  let(:user_password) { "admin!" * 4 }
  let(:other_user) { create(:user, login: "bob") }
  let(:admin) do
    create(:admin,
           password: user_password,
           password_confirmation: user_password)
  end

  before do
    login_as admin
  end

  it "forbids the admin editing his own account" do
    visit edit_user_path(admin, tab: :two_factor_authentication)
    expect(page).to have_css(".on-off-status.-disabled")

    expect(page).to have_no_css(".generic-table--empty-row", wait: 1)
    page.find(".admin--edit-section a").click

    expect(page).to have_css(".generic-table--empty-row")
    expect(page).to have_current_path my_2fa_devices_path
  end

  it "allows 2FA device management of the user" do
    visit edit_user_path(other_user, tab: :two_factor_authentication)

    # Visit empty index
    expect(page).to have_css(".generic-table--empty-row",
                             text: I18n.t("two_factor_authentication.admin.no_devices_for_user"))
    expect(page).to have_css(".on-off-status.-disabled")

    # Visit inline create
    find(".button", text: I18n.t("two_factor_authentication.admin.button_register_mobile_phone_for_user")).click

    SeleniumHubWaiter.wait
    # Try to save with invalid phone number
    fill_in "device_phone_number", with: "invalid!"
    click_button I18n.t(:button_continue)

    # Enter valid phone number
    expect_flash(type: :error, message: "Phone number must be of format +XX XXXXXXXXX")

    SeleniumHubWaiter.wait
    fill_in "device_phone_number", with: "+49 123456789"
    click_button I18n.t(:button_continue)

    expect(page).to have_css(".mobile-otp--two-factor-device-row td", text: "Mobile phone (bob) (+49 123456789)")
    expect(page).to have_css(".mobile-otp--two-factor-device-row td .icon-yes", count: 2)
    expect(page).to have_css(".on-off-status.-enabled")

    SeleniumHubWaiter.wait
    # Delete the one
    find(".two-factor--delete-button").click
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_css(".mobile-otp--two-factor-device-row", count: 0)
    expect(page).to have_css(".on-off-status.-disabled")
    expect(other_user.otp_devices.count).to eq 0
  end

  context "with multiple devices registered" do
    let!(:device1) { create(:two_factor_authentication_device_sms, user: other_user) }
    let!(:device2) { create(:two_factor_authentication_device_totp, user: other_user, default: false) }

    it "allows to delete all" do
      visit edit_user_path(other_user, tab: :two_factor_authentication)
      expect(page).to have_css(".mobile-otp--two-factor-device-row", count: 2)
      expect(page).to have_css(".on-off-status.-enabled")
      find(".button", text: I18n.t("two_factor_authentication.admin.button_delete_all_devices")).click

      page.driver.browser.switch_to.alert.accept

      expect(page).to have_css(".generic-table--empty-row",
                               text: I18n.t("two_factor_authentication.admin.no_devices_for_user"), wait: 20)
      expect(page).to have_css(".on-off-status.-disabled")
    end
  end
end

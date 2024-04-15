require_relative "../../spec_helper"
require_relative "../shared_2fa_examples"

RSpec.describe "Login by switching 2FA device", :js, with_settings: {
  plugin_openproject_two_factor_authentication: { "active_strategies" => %i[developer totp] }
} do
  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  context "with two default device" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: true) }
    let!(:device2) { create(:two_factor_authentication_device_totp, user:, active: true, default: false) }

    it "requests a 2FA and allows switching" do
      first_login_step

      expect(page).to have_css("input#otp")

      SeleniumHubWaiter.wait
      # Toggle device to TOTP
      find_by_id("toggle_resend_form").click

      SeleniumHubWaiter.wait
      find(".button--link[value='#{device2.redacted_identifier}']").click

      expect(page).to have_css("input#otp")
      expect(page).to have_css("#submit_otp p", text: device2.redacted_identifier)

      two_factor_step(device2.totp.now)
      expect_logged_in
    end
  end
end

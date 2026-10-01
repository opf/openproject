# frozen_string_literal: true

require_relative "../spec_helper"

# Regression test: find_user in BaseController used prepend_before_action, which ran it
# before ApplicationController#user_setup could set User.current from the session.
# User.visible defaults to User.current, so without User.current set to the admin,
# the target user was not found (404).
RSpec.describe "Admin deleting another user's 2FA device", :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: { "active_strategies" => %i[developer totp] }
               } do
  let(:dialog) { Components::PasswordConfirmationDialog.new }
  let(:admin_password) { "adminadmin!" * 2 }
  let(:admin) { create(:admin, password: admin_password, password_confirmation: admin_password) }
  let(:other_user) { create(:user) }
  let!(:device) { create(:two_factor_authentication_device_totp, user: other_user, default: false, active: true) }

  before do
    # Use a real browser login so the session is established via the normal auth flow
    # (user_setup callback), not via RequestStore stubbing. This exposes the
    # prepend_before_action ordering bug where find_user ran before User.current was set.
    login_with(admin.login, admin_password)
  end

  it "deletes the device" do
    visit edit_user_path(other_user, tab: :two_factor_authentication)

    expect(page).to have_css(".mobile-otp--two-factor-device-row", count: 1)

    find_test_selector("two-factor--actions-button").click
    find_test_selector("two-factor--delete-button").click
    dialog.confirm_flow_with(admin_password)

    expect(page).to have_css(".blankslate")
    expect(other_user.otp_devices.reload).to be_empty
  end
end

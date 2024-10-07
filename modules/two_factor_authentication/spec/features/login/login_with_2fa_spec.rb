require_relative "../../spec_helper"
require_relative "../shared_2fa_examples"

RSpec.describe "Login with 2FA device", :js, with_settings: {
  plugin_openproject_two_factor_authentication: {
    "active_strategies" => [:developer]
  }
} do
  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  context "with a default device" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: true) }

    it "requests a 2FA" do
      sms_token = nil
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
        .to receive(:create_mobile_otp).and_wrap_original do |m|
        sms_token = m.call
      end
      # rubocop:enable RSpec/AnyInstance

      first_login_step
      two_factor_step(sms_token)
      expect_logged_in
    end

    it "returns to 2FA page if invalid" do
      first_login_step
      two_factor_step("whatever")

      expect_flash(type: :error, message: I18n.t(:notice_account_otp_invalid))
      expect(page).to have_current_path signin_path
    end
  end
end

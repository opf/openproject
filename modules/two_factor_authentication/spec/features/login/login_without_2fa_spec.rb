require_relative "../../spec_helper"
require_relative "../shared_2fa_examples"

RSpec.describe "Login with no required OTP", :js, with_config: { "2fa": { active_strategies: [:developer] } } do
  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  context "non-default device" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: false) }

    it_behaves_like "login without 2FA"
  end

  context "not enabled",
          with_config: { "2fa": { active_strategies: [] } } do
    it_behaves_like "login without 2FA"
  end

  context "no device" do
    it_behaves_like "login without 2FA"
  end
end

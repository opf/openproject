require_relative "../../spec_helper"
require_relative "authentication_controller_shared_examples"

RSpec.describe TwoFactorAuthentication::AuthenticationController, with_settings: { login_required?: true } do
  let(:valid_credentials) do
    { username: "foobar", password: "AAA1111!!!!" }
  end
  let(:user) { create(:user, login: "foobar", password: "AAA1111!!!!", password_confirmation: "AAA1111!!!!") }

  before do
    # Assume the user has any memberships
    session[:stage_secrets] = { two_factor_authentication: "asdf" }

    without_partial_double_verification do
      allow_any_instance_of(User).to receive(:any_active_memberships?).and_return(true) # rubocop:disable RSpec/AnyInstance
    end
  end

  describe "with no active strategy", with_settings: { "plugin_openproject_two_factor_authentication" => {} } do
    before do
      session[:authenticated_user_id] = user.id
      get :request_otp
    end

    it_behaves_like "immediate success login"
  end

  describe "with no active strategy, but 2FA enforced as configuration",
           with_settings: { "plugin_openproject_two_factor_authentication" => { active_strategies: [], enforced: true } } do
    before do
      allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
        .to receive(:add_default_strategy?)
              .and_return false
      session[:authenticated_user_id] = user.id
      get :request_otp
    end

    it "returns a 500" do
      expect(response).to have_http_status :internal_server_error
    end
  end

  describe "with one active strategy, enforced", with_settings: {
    "plugin_openproject_two_factor_authentication" => { active_strategies: [:developer], enforced: true }
  } do
    context "with no device" do
      before do
        session[:authenticated_user_id] = user.id
        get :request_otp
      end

      it_behaves_like "2FA forced registry"
    end
  end

  describe "with one active strategy",
           with_settings: { "plugin_openproject_two_factor_authentication" => { active_strategies: [:developer] } } do
    context "with no device" do
      before do
        session[:authenticated_user_id] = user.id
        get :request_otp
      end

      # User can login without 2FA, since its not enforced
      it_behaves_like "immediate success login"
    end

    context "with a non-default device" do
      let!(:device) { create(:two_factor_authentication_device_sms, user:, default: false, channel: :sms) }

      before do
        session[:authenticated_user_id] = user.id
        get :request_otp
      end

      # User can login without 2FA, since its not enforced
      it_behaves_like "immediate success login"
    end

    context "with an invalid device" do
      let!(:device) { create(:two_factor_authentication_device_totp, user:, channel: :totp) }

      it_behaves_like "2FA login request failure", I18n.t("two_factor_authentication.error_no_matching_strategy")
    end

    context "with an active device" do
      let!(:device) { create(:two_factor_authentication_device_sms, user:, channel: :sms) }

      it_behaves_like "2FA SMS request success"
    end
  end

  describe "with two active strategy",
           with_settings: { "plugin_openproject_two_factor_authentication" => { active_strategies: %i[developer totp] } } do
    context "with a totp device" do
      let!(:device) { create(:two_factor_authentication_device_totp, user:, channel: :totp) }

      it_behaves_like "2FA TOTP request success"
    end

    context "with an sms device" do
      let!(:device) { create(:two_factor_authentication_device_sms, user:, channel: :sms) }

      it_behaves_like "2FA SMS request success"
    end
  end

  describe "#login_otp", "for a get request" do
    before do
      get :confirm_otp
    end

    it "receives a 405" do
      expect(response.response_code).to eq(405)
    end
  end
end

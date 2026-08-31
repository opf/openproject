# frozen_string_literal: true

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

      # User can login without 2FA, since it's not enforced
      it_behaves_like "immediate success login"
    end

    context "with a non-default device" do
      let!(:device) { create(:two_factor_authentication_device_sms, user:, default: false, channel: :sms) }

      before do
        session[:authenticated_user_id] = user.id
        get :request_otp
      end

      # User can login without 2FA, since it's not enforced
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

  describe "brute force protection",
           with_settings: {
             "plugin_openproject_two_factor_authentication" => { active_strategies: %i[developer totp] },
             brute_force_block_after_failed_logins: 5,
             brute_force_block_minutes: 30
           } do
    let!(:device) { create(:two_factor_authentication_device_totp, user:, channel: :totp) }

    before do
      session[:authenticated_user_id] = user.id
    end

    describe "POST confirm_otp with an invalid token" do
      before do
        post :confirm_otp, params: { otp: "000000" }
      end

      it "increments the failed_login_count" do
        expect(user.reload.failed_login_count).to eq 1
      end

      it "redirects to the stage failure path" do
        expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
      end
    end

    describe "POST confirm_otp when the user is already brute-force-blocked" do
      before do
        user.update!(failed_login_count: 5, last_failed_login_on: Time.zone.now)
        post :confirm_otp, params: { otp: "000000" }
      end

      it "redirects to the stage failure path" do
        expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
      end

      it "sets the blocked error message" do
        expect(flash[:error]).to eq I18n.t(:notice_account_invalid_credentials_or_blocked)
      end

      it "does not increment failed_login_count further" do
        expect(user.reload.failed_login_count).to eq 5
      end
    end

    describe "POST verify_backup_code with an invalid code" do
      before do
        post :verify_backup_code, params: { backup_code: "invalid-backup-code" }
      end

      it "increments the failed_login_count" do
        expect(user.reload.failed_login_count).to eq 1
      end

      it "redirects to the stage failure path" do
        expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
      end
    end

    describe "POST verify_backup_code when the user is already brute-force-blocked" do
      before do
        user.update!(failed_login_count: 5, last_failed_login_on: Time.zone.now)
        post :verify_backup_code, params: { backup_code: "any-code" }
      end

      it "redirects to the stage failure path" do
        expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
      end

      it "sets the blocked error message" do
        expect(flash[:error]).to eq I18n.t(:notice_account_invalid_credentials_or_blocked)
      end
    end
  end
end

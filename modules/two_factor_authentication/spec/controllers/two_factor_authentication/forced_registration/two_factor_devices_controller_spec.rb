require_relative "../../../spec_helper"
require_relative "../authentication_controller_shared_examples"

RSpec.describe TwoFactorAuthentication::ForcedRegistration::TwoFactorDevicesController do
  let(:user) { create(:user, login: "foobar") }
  let(:logged_in_user) { User.anonymous }
  let(:active_strategies) { [] }

  let(:authenticated_user_id) { user.id }
  let(:user_force_2fa) { true }

  include_context "with settings" do
    let(:settings) do
      {
        plugin_openproject_two_factor_authentication: {
          "active_strategies" => active_strategies
        }
      }
    end
  end

  before do
    allow(User).to receive(:current).and_return(User.anonymous)
    session[:authenticated_user_id] = authenticated_user_id
    session[:authenticated_user_force_2fa] = user_force_2fa
    session[:stage_secrets] = { two_factor_authentication: "asdf" }

    allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
      .to receive(:add_default_strategy?)
      .and_return false
  end

  describe "accessing" do
    before do
      get :new
    end

    context "when no authenticated_user present" do
      let(:active_strategies) { [:developer] }
      let(:authenticated_user_id) { nil }
      let(:user_force_2fa) { nil }

      it "does not give access" do
        expect(response).to be_redirect
        expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
      end
    end

    context "when logged in, but not enabled" do
      it "does not give access" do
        expect(response).to have_http_status :not_found
      end
    end

    context "when authenticated in and active strategies" do
      let(:active_strategies) { [:developer] }

      it "renders the new page" do
        expect(response).to be_successful
        expect(response).to render_template "two_factor_authentication/two_factor_devices/new_type"
      end
    end
  end

  describe "with active strategy" do
    let(:active_strategies) { [:developer] }

    describe "#new" do
      context "without type" do
        before do
          get :new
        end

        it "renders the new form" do
          expect(response).to be_successful
          expect(response).to render_template "new_type"
        end
      end

      context "with type" do
        before do
          get :new, params: { type: :sms }
        end

        it "renders the new form" do
          expect(response).to be_successful
          expect(response).to render_template "new"
        end
      end
    end

    describe "#register" do
      before do
        post :register, params: { key: :sms, device: params }
      end

      context "with missing phone" do
        let(:params) { { identifier: "foo" } }

        it "renders action new" do
          expect(response).to be_successful
          expect(response).to render_template "new"
          expect(assigns[:device]).to be_invalid
        end
      end

      context "with valid params" do
        let(:params) { { phone_number: "+49123456789", identifier: "foo" } }

        it "redirects to confirm" do
          device = user.otp_devices.reload.last
          expect(response).to redirect_to action: :confirm, device_id: device.id

          expect(device.identifier).to eq "foo (+49123456789)"
          expect(device.phone_number).to eq "+49123456789"
          expect(device.default).to be_falsey
          expect(device.active).to be_falsey
        end
      end
    end

    describe "#confirm" do
      describe "#get" do
        it "croaks on missing id" do
          get :confirm, params: { device_id: 1234 }
          expect(response).to have_http_status :not_found
        end

        describe "and registered totp device" do
          let(:active_strategies) { [:totp] }
          let!(:device) { create(:two_factor_authentication_device_totp, user:, active: false, default: false) }

          it "renders the confirmation page" do
            get :confirm, params: { device_id: device.id }
            expect(response).to be_successful
            expect(response).to render_template "confirm"
            expect(flash[:notice]).not_to be_present
          end
        end

        describe "with registered device" do
          let!(:device) { create(:two_factor_authentication_device_sms, user:, active: false, default: false) }

          it "renders the confirmation page" do
            get :confirm, params: { device_id: device.id }
            expect(response).to be_successful
            expect(response).to render_template "confirm"
          end

          it "redirects to failure path if token request failed" do
            allow_any_instance_of(TwoFactorAuthentication::TokenService)
              .to receive(:request)
              .and_return(ServiceResult.failure)

            get :confirm, params: { device_id: device.id }
            expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
            expect(flash[:error]).to include I18n.t("two_factor_authentication.devices.confirm_send_failed")
          end
        end
      end

      describe "#post" do
        it "croaks on missing id" do
          get :confirm, params: { device_id: 1234 }
          expect(response).to have_http_status :not_found
        end

        describe "and registered totp device" do
          let(:active_strategies) { [:totp] }
          let!(:device) { create(:two_factor_authentication_device_totp, user:, active: false, default: false) }

          it "renders a 400 on missing token" do
            post :confirm, params: { device_id: device.id }
            expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
          end

          it "redirects to the confirmation on faulty entry" do
            post :confirm, params: { device_id: device.id, otp: "1234" }
            expect(response).to redirect_to action: :confirm, device_id: device.id
            expect(flash[:error]).to include I18n.t("two_factor_authentication.devices.registration_failed_token_invalid")

            device.reload

            expect(device.active).to be false
            expect(device.default).to be false
          end

          it "activates the device when entered correctly and logs out the user" do
            allow(Sessions::DropAllSessionsService)
              .to receive(:call!)

            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(TwoFactorAuthentication::TokenService)
              .to receive(:verify)
              .with("1234")
              .and_return(ServiceResult.success)
            # rubocop:enable RSpec/AnyInstance

            post :confirm, params: { device_id: device.id, otp: "1234" }
            expect(response).to redirect_to stage_success_path(stage: :two_factor_authentication, secret: "asdf")
            expect(flash[:notice]).to include I18n.t("two_factor_authentication.devices.registration_complete")
            device.reload
            expect(device.active).to be true
            expect(device.default).to be true

            expect(Sessions::DropAllSessionsService)
              .to have_received(:call!).with(user)
          end
        end
      end
    end
  end
end

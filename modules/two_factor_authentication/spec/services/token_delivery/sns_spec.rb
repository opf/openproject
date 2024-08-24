require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

RSpec.describe OpenProject::TwoFactorAuthentication::TokenStrategy::Sns do
  describe "sending messages" do
    let(:phone) { "+49 123456789" }
    let!(:user) { create(:user) }
    let!(:device) { create(:two_factor_authentication_device_sms, user:, channel:) }
    let(:channel) { :sms }

    let(:sns_params) do
      {
        region: "eu-west-1",
        access_key_id: "foobar",
        secret_access_key: "foobar key"
      }
    end

    include_context "with settings" do
      let(:settings) do
        {
          plugin_openproject_two_factor_authentication: {
            "active_strategies" => [:sns],
            "sns" => sns_params
          }
        }
      end
    end

    before do
      allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Sns)
        .to receive(:create_mobile_otp)
        .and_return("1234")
    end

    describe "#setup" do
      context "for valid params" do
        it "validates without errors" do
          expect { described_class.validate! }
            .not_to raise_exception
        end
      end

      context "for incomplete params" do
        let(:sns_params) { { region: nil } }

        it "raises an exception" do
          expect { described_class.validate! }
            .to raise_exception(ArgumentError)
        end
      end
    end

    describe "calling a mocked AWS API" do
      subject { TwoFactorAuthentication::TokenService.new user: }

      let(:result) { subject.request }
      let(:api) { instance_double(Aws::SNS::Client) }

      before do
        expect(Aws::SNS::Client).to receive(:new).and_return api
      end

      context "assuming invalid credentials" do
        before do
          expect(api)
            .to receive(:set_sms_attributes)
            .with(any_args)
            .and_raise("The security token included in the request is invalid.")
        end

        it "does not raise an exception out of delivery" do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq([I18n.t("two_factor_authentication.sns.delivery_failed")])
        end
      end

      context "assuming valid credential" do
        let(:api_result) { double }

        before do
          allow(api_result).to receive(:message_id).and_return :bla

          expect(api).to receive(:set_sms_attributes).and_return(nil)
          expect(api)
            .to receive(:publish)
            .with({ phone_number: phone.delete(" "),
                    message: I18n.t("two_factor_authentication.text_otp_delivery_message_sms",
                                    app_title: Setting.app_title, token: 1234) })
            .and_return(api_result)
        end

        it "returns a successful delivery" do
          expect(result).to be_success
        end
      end
    end
  end
end

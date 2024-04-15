require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require "messagebird"

RSpec.describe OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird do
  describe "sending messages" do
    let!(:user) { create(:user, language: locale) }
    let!(:locale) { "en" }
    let!(:device) { create(:two_factor_authentication_device_sms, user:, channel:) }

    let(:service_url) { "https://example.org/foobar" }
    let(:apikey) { "whatever" }
    let(:params) do
      {
        apikey:
      }
    end

    let(:result) { subject.request }

    subject { TwoFactorAuthentication::TokenService.new user: }

    include_context "with settings" do
      let(:settings) do
        {
          plugin_openproject_two_factor_authentication: {
            "active_strategies" => [:message_bird],
            "message_bird" => params
          }
        }
      end
    end

    before do
      allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird)
        .to receive(:create_mobile_otp)
        .and_return("1234")
    end

    describe "#setup" do
      let(:channel) { :sms }
      let(:params) { { apikey: nil } }

      it "raises an exception for incomplete params" do
        expect { described_class.validate! }
          .to raise_exception(ArgumentError)
      end
    end

    describe "calling a mocked test API" do
      let(:channel) { :sms }

      before do
        allow(MessageBird::Client).to receive(:new)
      end

      it "uses the api key defined in the settings" do
        result
        expect(MessageBird::Client).to have_received(:new).with(apikey)
      end
    end

    describe "calling the real test API" do
      let(:apikey) { ENV.fetch("MESSAGEBIRD_TEST_APIKEY", nil) }

      before do
        skip "Missing MESSAGEBIRD_TEST_APIKEY environment variable" unless apikey.present?
      end

      context "with SMS" do
        let(:channel) { :sms }

        it "returns success in the service" do
          expect(result).to be_success
        end
      end

      context "with VOICE" do
        let(:channel) { :voice }

        it "returns success in the service" do
          expect(result).to be_success
        end
      end
    end

    describe "calling a mocked API Client" do
      let(:messagebird) { instance_double(MessageBird::Client) }

      let(:failed_count) { 0 }
      let(:response) { instance_double(MessageBird::Message, recipients: { "totalDeliveryFailedCount" => failed_count }) }
      let(:channel) { :sms }

      before do
        allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird)
          .to receive(:message_bird_client)
          .and_return(messagebird)
      end

      context "with SMS" do
        before do
          allow(messagebird)
            .to receive(:message_create)
            .with(Setting.app_title,
                  "49123456789",
                  I18n.t("two_factor_authentication.text_otp_delivery_message_sms", app_title: Setting.app_title, token: "1234"),
                  validity: 720)
            .and_return(response)
        end

        it "returns success in the service" do
          expect(result).to be_success
        end

        context "failure" do
          let(:failed_count) { 1 }

          it "returns error in the service" do
            expect(result).not_to be_success
            expect(result.errors).to be_present
          end
        end
      end

      context "with voice" do
        let(:channel) { :voice }
        let(:expected_language) { :"en-us" }

        before do
          allow(subject.strategy)
            .to receive(:has_localized_text?)
                  .with(locale)
                  .and_return true

          allow(messagebird)
            .to receive(:voice_message_create)
            .and_return(response)
        end

        it "returns success in the service" do
          expect(result).to be_success
          expect(messagebird)
            .to have_received(:voice_message_create)
                  .with("49123456789",
                        subject.strategy.send(:localized_message, locale, "1234"),
                        ifMachine: :continue,
                        language: expected_language)
        end

        context "failure" do
          let(:failed_count) { 1 }

          it "returns error in the service" do
            expect(result).not_to be_success
            expect(result.errors).to be_present
          end
        end

        context "with german locale" do
          let(:locale) { "de" }
          let(:expected_language) { :"de-de" }

          it "returns success in the service" do
            expect(result).to be_success
            expect(messagebird)
              .to have_received(:voice_message_create)
                    .with("49123456789",
                          subject.strategy.send(:localized_message, locale, "1234"),
                          ifMachine: :continue,
                          language: expected_language)
          end
        end
      end
    end
  end
end

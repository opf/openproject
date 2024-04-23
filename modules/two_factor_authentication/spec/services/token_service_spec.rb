require_relative "../spec_helper"

RSpec.describe TwoFactorAuthentication::TokenService do
  describe "sending messages" do
    let(:user) { create(:user) }
    let(:dev_strategy) { OpenProject::TwoFactorAuthentication::TokenStrategy::Developer }
    let(:configuration) do
      {
        "active_strategies" => active_strategies,
        "enforced" => enforced
      }
    end
    let(:enforced) { false }

    let(:result) { subject.request }

    subject { described_class.new user: }

    include_context "with settings" do
      let(:settings) do
        {
          plugin_openproject_two_factor_authentication: configuration
        }
      end
    end

    context "when no strategy is set" do
      let(:active_strategies) { [] }

      context "when enforced" do
        let(:enforced) { true }

        before do
          allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
            .to receive(:add_default_strategy?)
            .and_return false
        end

        it "requires a token" do
          expect(subject).to be_requires_token
        end

        it "returns error when requesting" do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t("two_factor_authentication.error_2fa_disabled")]
        end
      end

      context "when not enforced" do
        let(:enforced) { false }

        before do
          allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
            .to receive(:add_default_strategy?)
            .and_return false
        end

        it "requires no token" do
          expect(subject).not_to be_requires_token
        end

        it "returns error when requesting" do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t("two_factor_authentication.error_2fa_disabled")]
        end
      end
    end

    context "when developer strategy is set" do
      let(:active_strategies) { [:developer] }

      context "when no device exists" do
        it "returns an error" do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t("two_factor_authentication.error_no_device")]
        end
      end

      context "when matching device exists" do
        let!(:device) { create(:two_factor_authentication_device_sms, user:, default: true) }

        it "submits the request" do
          expect(subject).to be_requires_token
          expect(result).to be_success
          expect(result.errors).to be_empty
        end
      end

      context "when non-matching device exists" do
        let!(:device) { create(:two_factor_authentication_device_totp, user:, default: true) }

        it "submits the request" do
          expect(subject).to be_requires_token
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t("two_factor_authentication.error_no_matching_strategy")]
        end
      end
    end

    context "when developer and totp strategies are set" do
      let(:active_strategies) { %i[developer totp] }
      let!(:totp_device) { create(:two_factor_authentication_device_totp, user:, default: true) }
      let!(:sms_device) { create(:two_factor_authentication_device_sms, user:, default: false) }

      subject { described_class.new user:, use_device: }

      context "with default device/channel" do
        let(:use_device) { nil }

        it "uses the totp device" do
          expect(subject).to be_requires_token
          expect(result).to be_success
          expect(result.errors).to be_empty

          expect(subject.strategy.identifier).to eq :totp
          expect(subject.strategy.channel).to eq :totp
        end
      end

      context "with overridden device" do
        let(:use_device) { sms_device }

        it "uses the overridden device" do
          expect(subject).to be_requires_token
          expect(result).to be_success
          expect(result.errors).to be_empty

          expect(subject.strategy.identifier).to eq :developer
          expect(subject.strategy.channel).to eq :sms
        end
      end
    end
  end
end

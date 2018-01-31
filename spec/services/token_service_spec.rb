require_relative '../spec_helper'

describe ::TwoFactorAuthentication::TokenService, with_2fa_ee: true do
  describe 'sending messages' do
    let(:user) { FactoryGirl.create(:user) }
    let(:dev_strategy) { ::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer }
    let(:configuration) do
      {
        active_strategies: active_strategies,
        enforced: enforced
      }
    end
    let(:enforced) { false }

    before do
      allow(OpenProject::Configuration)
      .to receive(:[]).with('2fa')
      .and_return(configuration)
    end

    subject { described_class.new user: user }
    let(:result) { subject.request }

    context 'when no strategy is set' do
      let(:active_strategies) { [] }

      context 'when enforced' do
        before do
          allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
            .to receive(:add_default_strategy?)
            .and_return false
        end

        let(:enforced) { true }
        it 'requires a token' do
          expect(subject.requires_token?).to be_truthy
        end

        it 'returns error when requesting' do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t('two_factor_authentication.error_2fa_disabled')]
        end
      end

      context 'when not enforced' do
        let(:enforced) { false }
        before do
          allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
            .to receive(:add_default_strategy?)
            .and_return false
        end

        it 'requires no token' do
          expect(subject.requires_token?).to be_falsey
        end

        it 'returns error when requesting' do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t('two_factor_authentication.error_2fa_disabled')]
        end
      end
    end

    context 'when developer strategy is set' do
      let(:active_strategies) { [:developer] }

      context 'but no device exists' do
        it 'returns an error' do
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t('two_factor_authentication.error_no_device')]
        end
      end

      context 'and matching device exists' do
        let!(:device) { FactoryGirl.create :two_factor_authentication_device_sms, user: user, default: true }

        it 'submits the request' do
          expect(subject.requires_token?).to be_truthy
          expect(result).to be_success
          expect(result.errors).to be_empty
        end
      end

      context 'and non-matching device exists' do
        let!(:device) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: true }

        it 'submits the request' do
          expect(subject.requires_token?).to be_truthy
          expect(result).not_to be_success
          expect(result.errors.full_messages).to eq [I18n.t('two_factor_authentication.error_no_matching_strategy')]
        end
      end
    end

    context 'when developer and totp strategies are set' do
      let(:active_strategies) { [:developer, :totp] }
      let!(:totp_device) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: true }
      let!(:sms_device) { FactoryGirl.create :two_factor_authentication_device_sms, user: user, default: false }

      subject { described_class.new user: user, use_device: use_device }

      context 'with default device/channel' do
        let(:use_device) { nil }

        it 'uses the totp device' do
          expect(subject.requires_token?).to be_truthy
          expect(result).to be_success
          expect(result.errors).to be_empty

          expect(subject.strategy.identifier).to eq :totp
          expect(subject.strategy.channel).to eq :totp
        end
      end

      context 'with overriden device' do
        let(:use_device) { sms_device }
        it 'uses the overridden device' do
          expect(subject.requires_token?).to be_truthy
          expect(result).to be_success
          expect(result.errors).to be_empty

          expect(subject.strategy.identifier).to eq :developer
          expect(subject.strategy.channel).to eq :sms
        end
      end
    end
  end
end

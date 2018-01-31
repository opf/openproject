require_relative '../spec_helper'

describe ::OpenProject::TwoFactorAuthentication::TokenStrategyManager do
  let(:dev_strategy) { ::OpenProject::TwoFactorAuthentication::TokenStrategy::Developer }
  let(:totp_strategy) { ::OpenProject::TwoFactorAuthentication::TokenStrategy::Totp }
  let(:configuration) do
    {
      active_strategies: active_strategies,
      enforced: enforced
    }
  end
  let(:enforced) { false }

  context 'without EE' do
    before do
      allow(OpenProject::Configuration)
          .to receive(:[]).with('2fa')
                  .and_return(active_strategies: [:developer])
    end

    it 'is not enabled' do
      expect(described_class).not_to be_enabled
    end
  end

  context 'with EE', with_2fa_ee: true do
    before do
      allow(OpenProject::Configuration)
      .to receive(:[]).with('2fa')
      .and_return(configuration)
    end

    describe '#find_matching_strategy' do
      subject { described_class.find_matching_strategy(:sms) }

      context 'when no strategy is set' do
        let(:active_strategies) { [] }
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when matching strategy exists' do
        let(:active_strategies) { [:developer] }

        it 'returns the strategy' do
          expect(subject).to eq(dev_strategy)
        end
      end

      context 'when non-matching strategy exists' do
        let(:active_strategies) { [:totp] }

        it 'returns the strategy' do
          expect(subject).to eq(nil)
        end
      end
    end

    describe '#active_strategies' do
      context 'with bogus strategy' do
        let(:active_strategies) { [:doesnotexist] }

        it 'raises when accessing' do
          expect { described_class.active_strategies }.to raise_error(ArgumentError)
        end

        it 'raises when validating' do
          expect { described_class.validate_active_strategies! }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'with additional settings given' do
      let(:active_strategies) { [:developer] }
      let(:enforced) { false }

      before do
        allow(Setting).to receive(:plugin_openproject_two_factor_authentication).and_return(settings)
      end

      context 'when nothing given' do
        let(:settings) { nil }

        it 'uses the configuration' do
          expect(described_class.active_strategies).to eq([dev_strategy])
          expect(described_class).not_to be_enforced
        end
      end

      context 'when additional strategy given' do
        let(:settings) { { active_strategies: [:totp] } }

        it 'merges configuration and settings' do
          expect(described_class.active_strategies).to eq([dev_strategy, totp_strategy])
          expect(described_class).not_to be_enforced
        end
      end

      context 'when enforced set' do
        context 'when true and config is false' do
          let(:enforced) { false }
          let(:settings) { { enforced: true } }

          it 'does override the configuration' do
            expect(described_class).to be_enforced
          end
        end

        context 'when false and config is true' do
          let(:enforced) { true }
          let(:settings) { { enforced: false } }

          it 'does not override the configuration' do
            expect(described_class).to be_enforced
          end
        end
      end
    end

    describe '#validate_active_strategies!' do
      subject { described_class.validate_active_strategies! }
      context 'when no strategy is set' do
        let(:active_strategies) { [] }
        before do
          allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
            .to receive(:add_default_strategy?)
            .and_return false
        end

        context 'and enforced is false' do
          let(:enforced) { false }

          it 'accepts that' do
            expect { subject }.not_to raise_error
            expect(described_class).not_to be_enabled
            expect(described_class).not_to be_enforced
          end
        end

        context 'and enforced is true' do
          let(:enforced) { true }

          it 'raises and error that a strategy is needed' do
            expect { subject }.to raise_error(ArgumentError)
            expect(described_class).not_to be_enabled
            expect(described_class).to be_enforced
          end
        end
      end

      context 'when a strategy is set' do
        let(:active_strategies) { [:developer] }

        context 'and it is valid' do
          it 'returns that' do
            expect { subject }.not_to raise_error
            expect(described_class.active_strategies).to eq([dev_strategy])
            expect(described_class).to be_enabled
            expect(described_class).not_to be_enforced
          end
        end

        context 'and it is invalid' do
          before do
            expect(dev_strategy).to receive(:validate!).and_raise 'Error!'
          end
          it 'raises' do
            expect { subject }.to raise_error 'Error!'
            expect(described_class).to be_enabled
            expect(described_class).not_to be_enforced
          end
        end
      end
    end
  end
end
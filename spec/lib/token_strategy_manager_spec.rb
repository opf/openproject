require 'spec_helper'

describe ::OpenProject::TwoFactorAuthentication::TokenStrategyManager do
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

  describe '#validate_active_strategies!' do
    subject { described_class.validate_active_strategies! }
    context 'when no strategy is set' do
      let(:active_strategies) { [] }

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
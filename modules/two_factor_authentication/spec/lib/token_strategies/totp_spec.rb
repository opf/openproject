require_relative '../../spec_helper'

describe OpenProject::TwoFactorAuthentication::TokenStrategy::Totp do
  shared_let(:user) { create(:user) }
  let(:channel) { :totp }
  let(:strategy) { described_class.new user:, device:, channel: }

  before do
    allow(device).to receive(:verify_token).and_return(verify_result)
  end

  describe 'verify failure' do
    let(:verify_result) { false }

    subject { strategy.verify 'input' }

    context 'with active device' do
      let(:device) { build(:two_factor_authentication_device_sms, user:, channel:, active: true) }

      it 'raises a standard error on failure' do
        expect { subject }.to raise_error('Invalid one-time password.')
      end
    end

    context 'with inactive device' do
      let(:device) { build(:two_factor_authentication_device_sms, user:, channel:, active: false) }

      it 'raises an extended error on failure' do
        expected = /If this happens repeatedly, please make sure your device clock is in sync/
        expect { subject }.to raise_error(expected)
      end
    end
  end
end

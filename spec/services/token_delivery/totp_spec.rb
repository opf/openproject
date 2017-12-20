require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe ::OpenProject::TwoFactorAuthentication::TokenStrategy::Totp, with_2fa_ee: true do
  describe 'sending messages' do
    let!(:user) { FactoryGirl.create :user }
    let!(:device) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: true}

    before do
      allow(OpenProject::Configuration)
        .to receive(:[]).with('2fa')
        .and_return(active_strategies: [:totp])
    end

    describe '#verify' do
      subject { ::TwoFactorAuthentication::TokenService.new user: user }
      let(:result) { subject.verify token }

      context '#valid current token' do
        let(:token) { device.totp.now }

        it 'is validated' do
          expect(result).to be_success
        end

        it 'is validated only once' do
          expect(subject.verify(token)).to be_success

          # Last OTP date is remembered for the device.
          expect(subject.verify(token)).not_to be_success
        end
      end

      context 'invalid token' do
        let(:token) { 'definitely invalid' }

        it 'is not validated' do
          expect(result).not_to be_success
          expect(result.errors[:base]).to include I18n.t(:notice_account_otp_invalid)
        end
      end

      context 'assuming internal error' do
        let(:token) { 1234 }

        before do
          allow_any_instance_of(::TwoFactorAuthentication::Device::Totp)
            .to receive(:verify_token).and_raise 'Some internal error!'
        end

        it 'returns a successful delivery' do
          expect(result).not_to be_success
          expect(result.errors[:base]).to include 'Some internal error!'
        end
      end
    end
  end
end

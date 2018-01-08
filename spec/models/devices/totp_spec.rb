require 'spec_helper'
require 'timecop'

describe ::TwoFactorAuthentication::Device::Totp, with_2fa_ee: true, type: :model do
  let(:user) { FactoryGirl.create :user }
  let(:channel) { :totp }
  subject { described_class.new identifier: 'foo', channel: channel, user: user, active: true }

  describe 'validations' do
    context 'with invalid channel' do
      let(:channel) { :whatver }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:channel]).to be_present
      end
    end

    context 'with valid channel' do
      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors).to be_empty
      end
    end
  end

  describe 'token validation' do
    let(:totp) { subject.send :totp }

    context 'drift', with_config: { :'2fa' =>  { otp_drift_window: 30 } } do
      it 'uses the drift window from configuration' do
        expect(subject.allowed_drift).to eq 30
      end
    end

    context 'no drift set' do
      it 'uses the default drift window' do
        expect(subject.allowed_drift).to eq 60
      end

      it 'uses the drift value for verification' do
        # Assume never used
        allow(subject).to receive(:last_used_at).and_return nil
        allow(subject).to receive(:update_column).with(:last_used_at, any_args)

        Timecop.freeze(Time.now) do
          old_valid = totp.at(Time.now - 30.seconds)
          old_valid2 = totp.at(Time.now - 60.seconds)
          new_valid = totp.at(Time.now + 30.seconds)
          new_valid2 = totp.at(Time.now + 60.seconds)

          # Next iteration at interval is 90
          # which should be invalid
          old_invalid = totp.at(Time.now - 90.seconds)
          new_invalid = totp.at(Time.now + 90.seconds)

          expect(subject.verify_token(old_valid)).to eq true
          expect(subject.verify_token(old_valid2)).to eq true
          expect(subject.verify_token(new_valid)).to eq true
          expect(subject.verify_token(new_valid2)).to eq true

          expect(subject.verify_token(old_invalid)).to eq false
          expect(subject.verify_token(new_invalid)).to eq false
        end
      end
    end

    it 'avoids double verification' do
      subject.save!

      valid = totp.at(Time.now)
      expect(subject.verify_token(valid)).to eq true
      last_date = subject.last_used_at
      expect(last_date).to be_present

      expect(subject.verify_token(valid)).to eq false

      future = Time.now + 1.minute
      Timecop.freeze(future) do
        valid = totp.now
        expect(subject.verify_token(valid)).to eq true
        expect(subject.verify_token(valid)).to eq false
      end
    end
  end
end

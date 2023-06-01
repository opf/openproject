require 'spec_helper'
require 'timecop'

RSpec.describe TwoFactorAuthentication::Device::Totp do
  let(:user) { create(:user) }
  let(:channel) { :totp }

  subject { described_class.new identifier: 'foo', channel:, user:, active: true }

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

    context 'when setting drift',
            with_settings: {
              plugin_openproject_two_factor_authentication: {
                'otp_drift_window' => 30
              }
            } do
      it 'uses the drift window from configuration' do
        expect(subject.allowed_drift).to eq 30
      end
    end

    context 'when no drift set' do
      it 'uses the default drift window' do
        expect(subject.allowed_drift).to eq 60
      end

      it 'uses the drift value for verification' do
        # Assume never used
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:last_used_at).and_return nil
        allow(subject).to receive(:update_column).with(:last_used_at, any_args)
        # rubocop:enable RSpec/SubjectStub

        Timecop.freeze(Time.current) do
          old_valid = totp.at(30.seconds.ago)
          old_valid2 = totp.at(60.seconds.ago)
          new_valid = totp.at(30.seconds.from_now)
          new_valid2 = totp.at(60.seconds.from_now)

          # Next iteration at interval is 90
          # which should be invalid
          old_invalid = totp.at(90.seconds.ago)
          new_invalid = totp.at(90.seconds.from_now)

          expect(subject.verify_token(old_valid)).to be true
          expect(subject.verify_token(old_valid2)).to be true
          expect(subject.verify_token(new_valid)).to be true
          expect(subject.verify_token(new_valid2)).to be true

          expect(subject.verify_token(old_invalid)).to be false
          expect(subject.verify_token(new_invalid)).to be false
        end
      end
    end

    it 'avoids double verification' do
      subject.save!

      valid = totp.at(Time.current)
      expect(subject.verify_token(valid)).to be true
      last_date = subject.last_used_at
      expect(last_date).to be_present

      expect(subject.verify_token(valid)).to be false

      future = 1.minute.from_now
      Timecop.freeze(future) do
        valid = totp.now
        expect(subject.verify_token(valid)).to be true
        expect(subject.verify_token(valid)).to be false
      end
    end
  end
end

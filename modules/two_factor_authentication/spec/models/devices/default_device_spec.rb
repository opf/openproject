require 'spec_helper'

RSpec.describe 'Default device' do
  let(:user) { create(:user) }
  let(:other_otp) { build(:two_factor_authentication_device_totp, user:, default: true) }

  subject { build(:two_factor_authentication_device_totp, user:, default: true) }

  it 'can be set if nothing else exists' do
    expect(subject.save).to be true

    expect(other_otp).to be_invalid
    expect(other_otp.errors[:default]).to include 'is already set for another OTP device.'
  end

  context 'assuming another default exists' do
    let(:other_otp) { create(:two_factor_authentication_device_totp, user:, default: true) }
    let(:other_sms) { create(:two_factor_authentication_device_sms, user:, default: false) }

    subject { create(:two_factor_authentication_device_totp, user:, default: false) }

    before do
      other_otp
      other_sms
      subject
    end

    it 'can be set through make_default!' do
      expect(user.otp_devices.count).to eq(3)
      expect(user.otp_devices.get_default).to eq(other_otp)

      subject.make_default!
      expect(user.otp_devices.reload.get_default).to eq(subject)
    end
  end
end

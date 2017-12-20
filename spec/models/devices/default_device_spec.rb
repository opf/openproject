require 'spec_helper'

describe 'Default device', with_2fa_ee: true, type: :model do
  let(:user) { FactoryGirl.create :user }
  let(:subject) { FactoryGirl.build :two_factor_authentication_device_totp, user: user, default: true }
  let(:other_otp) { FactoryGirl.build :two_factor_authentication_device_totp, user: user, default: true }

  it 'can be set if nothing else exists' do
    expect(subject.save).to eq true

    expect(other_otp).to be_invalid
    expect(other_otp.errors[:default]).to include 'is already set for another OTP device.'
  end

  context 'assuming another default exists' do
    let(:other_otp) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: true }
    let(:other_sms) { FactoryGirl.create :two_factor_authentication_device_sms, user: user, default: false }
    let(:subject) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: false }

    before do
      other_otp
      other_sms
      subject
    end

    it 'can be set through make_default!' do
      expect(user.otp_devices.count).to eq(3)
      expect(user.otp_devices.get_default).to eq(other_otp)

      subject.make_default!
      expect(user.otp_devices.get_default).to eq(subject)
    end
  end
end
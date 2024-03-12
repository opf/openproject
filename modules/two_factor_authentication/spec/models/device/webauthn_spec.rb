require 'spec_helper'

RSpec.describe TwoFactorAuthentication::Device::Webauthn do
  let(:user) { create(:user) }

  subject { build(:two_factor_authentication_device_webauthn, user:) }

  it { is_expected.to validate_presence_of(:webauthn_external_id) }
  it { is_expected.to validate_presence_of(:webauthn_public_key) }
end

require 'spec_helper'

RSpec.describe TwoFactorAuthentication::Device::Webauthn do
  subject { create(:two_factor_authentication_device_webauthn) }

  it { is_expected.to validate_presence_of(:webauthn_external_id) }
  it { is_expected.to validate_uniqueness_of(:webauthn_external_id).scoped_to(:user_id) }
  it { is_expected.to validate_presence_of(:webauthn_public_key) }
end

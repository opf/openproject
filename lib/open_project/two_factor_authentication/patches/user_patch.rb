module OpenProject::TwoFactorAuthentication::Patches
  module UserPatch
    def self.included(base)
      base.class_eval do
        has_many :otp_tokens, class_name: 'TwoFactorAuthentication::LoginToken', dependent: :destroy
        has_many :otp_devices, class_name: 'TwoFactorAuthentication::Device', dependent: :destroy
      end
    end
  end
end

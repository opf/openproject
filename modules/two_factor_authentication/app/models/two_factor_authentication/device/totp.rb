require 'rotp'
require_dependency 'two_factor_authentication/device'

module TwoFactorAuthentication
  class Device::Totp < Device
    validates_presence_of :otp_secret

    def device_type
      :totp
    end

    # Check allowed channels
    def self.supported_channels
      %i(totp)
    end
    validates_inclusion_of :channel, in: supported_channels

    # Generate Authy/Authenticator compatible secret with rotp
    after_initialize do
      self.otp_secret ||= ::ROTP::Base32.random_base32
      self.channel ||= :totp
    end

    ##
    # verify the given OTP input
    def verify_token(token)
      result = totp.verify_with_drift_and_prior(token.to_s, allowed_drift, last_used_at)

      if result.nil?
        false
      else
        update_column(:last_used_at, result)
        true
      end
    end

    ##
    #
    def account_name
      if user.present?
        user.login
      else
        model_name.human
      end
    end

    ##
    #
    def request_2fa_identifier(_channel)
      identifier
    end

    ##
    # Output the provisioning URL for the user
    # can be generated into a QR for mobile apps.
    def provisioning_url
      totp.provisioning_uri(account_name)
    end

    def allowed_drift
      self.class.manager.configuration.fetch :otp_drift_window, 60
    end

    def totp
      @totp ||= ::ROTP::TOTP.new otp_secret, issuer: (Setting.app_title.presence || 'OpenProject')
    end
  end
end
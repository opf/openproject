module TwoFactorAuthentication
  class Device::Webauthn < Device
    validates :webauthn_external_id, presence: true, uniqueness: true
    validates :webauthn_public_key, presence: true

    # Check allowed channels
    def self.supported_channels
      %i(webauthn)
    end

    def self.device_type
      :webauthn
    end

    # Set default channel
    after_initialize do
      self.channel ||= :webauthn
    end
    validates_inclusion_of :channel, in: supported_channels
  end
end

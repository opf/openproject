module TwoFactorAuthentication
  class Device::Webauthn < Device
    validates :webauthn_external_id, presence: true, uniqueness: { scope: :user_id }
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

    def options_for_create(relying_party)
      @options_for_create ||= relying_party.options_for_registration(
        user: { id: user.webauthn_id, name: user.name },
        exclude: TwoFactorAuthentication::Device::Webauthn.where(user:).pluck(:webauthn_external_id)
      )
    end

    def options_for_get(relying_party)
      @options_for_get ||= relying_party.options_for_authentication(
        allow: [webauthn_external_id] # TODO: Maybe also allow all other tokens? Let's see
      )
    end

    def request_2fa_identifier(_channel)
      identifier
    end

    def input_based?
      false
    end
  end
end

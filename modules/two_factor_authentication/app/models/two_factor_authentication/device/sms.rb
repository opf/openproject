require_dependency 'two_factor_authentication/device'

module TwoFactorAuthentication
  class Device::Sms < Device
    validates_presence_of :phone_number
    validates_uniqueness_of :phone_number, scope: :user_id
    validates_format_of :phone_number, with: /\A(?:\+(?:[0-9][- ]?)+[0-9])?\z/, message: :error_phone_number_format

    # Check allowed channels
    def self.supported_channels
      %i(sms voice)
    end

    def self.device_type
      :sms
    end

    # Set default channel
    after_initialize do
      self.channel ||= :sms
    end

    validates_inclusion_of :channel, in: supported_channels

    def identifier
      value = read_attribute(:identifier)

      if value
        "#{value} (#{phone_number})"
      else
        default_identifier
      end
    end

    def default_identifier
      if phone_number.present?
        "#{name} (#{phone_number})"
      else
        "#{name} (#{user.login})"
      end
    end

    ##
    #
    def request_2fa_identifier(channel)
      channel_name =
        if channel == :sms
          'SMS'
        else
          'Voice'
        end

      I18n.t 'two_factor_authentication.devices.sms.request_2fa_identifier',
             redacted_identifier: redacted_identifier, delivery_channel: channel_name
    end

    def redacted_identifier
      number = phone_number.dup
      number[1..-3] = '*' * number[1..-3].length
      I18n.t 'two_factor_authentication.devices.sms.redacted_identifier',
             redacted_number: number
    end

    def phone_number=(number)
      super(number.try(:strip))
    end
  end
end
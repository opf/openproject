# frozen_string_literal: true

module TwoFactorAuthentication
  module Devices
    class TotpQrCodeComponent < ViewComponent::Base
      def initialize(device:)
        super()
        @device = device
      end
    end
  end
end

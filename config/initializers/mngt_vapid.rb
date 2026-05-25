# frozen_string_literal: true

module Mngt
  module Vapid
    def self.public_key
      ENV.fetch("MNGT_VAPID_PUBLIC_KEY", "")
    end

    def self.private_key
      ENV.fetch("MNGT_VAPID_PRIVATE_KEY", "")
    end

    def self.configured?
      public_key.present? && private_key.present?
    end
  end
end

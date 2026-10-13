# frozen_string_literal: true

module TwoFactorAuthentication
  class LoginToken < ::Token::HashedToken
    include ::Token::Ephemeral

    def self.validity_time
      15.minutes
    end

    def self.generate_token_value
      chars = ("0".."9").to_a
      Array.new(6) { chars[SecureRandom.rand(chars.size)] }.join
    end
  end
end

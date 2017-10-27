module TwoFactorAuthentication
  class LoginToken < ::ExtendedToken
    def self.validity_time
      15.minutes
    end

    private

    def self.generate_token_value
      chars = ("0".."9").to_a
      password = ''
      6.times { |i| password << chars[rand(chars.size-1)] }
      password
    end

  end
end
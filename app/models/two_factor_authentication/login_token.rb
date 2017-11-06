require_dependency 'token/hashed_token'
require_dependency 'token/expirable_token'

module TwoFactorAuthentication
  class LoginToken < ::Token::HashedToken
    include ::Token::ExpirableToken

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
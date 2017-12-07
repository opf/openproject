require_dependency 'token/hashed_token'

module TwoFactorAuthentication
  class BackupCode < ::Token::HashedToken
    class << self

      def regenerate!(user)
        backup_codes = []

        transaction do
          where(user_id: user.id).delete_all
          10.times do
            code = new(user: user)
            code.save!
            backup_codes << code.plain_value
          end
        end

        backup_codes
      end

      ##
      # The default token value is 32 bytes in hex
      # which is a bit large for a one-use token
      def generate_token_value
        SecureRandom.hex(8)
      end
    end

    ##
    # Allows only a single value of the token?
    def single_value?
      false
    end
  end
end
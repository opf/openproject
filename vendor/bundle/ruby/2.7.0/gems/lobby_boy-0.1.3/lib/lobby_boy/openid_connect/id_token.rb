module LobbyBoy
  module OpenIDConnect
    ##
    # Wraps a OpenIDConnect::ResponseObject::IdToken providing some useful
    # methods for it.
    class IdToken < SimpleDelegator
      attr_accessor :jwt_token

      ##
      # Creates a new IdToken by decoding the given JWT token using the given public key.
      #
      # @param jwt_token [String] The JWT token received from the OpenID Connect provider.
      # @param public_key [String] Public key or secret. Only required for signed tokens.
      def initialize(jwt_token, public_key = nil)
        @jwt_token = jwt_token
        id_token = ::OpenIDConnect::ResponseObject::IdToken.decode jwt_token, public_key
        super id_token
      end

      def expires_at
        datetime_from_seconds __getobj__.exp
      end

      def issued_at
        datetime_from_seconds __getobj__.iat
      end

      ##
      # Number of seconds left until this ID token expires.
      def expires_in
        [0, __getobj__.exp - Time.now.to_i].max
      end

      def datetime_from_seconds(seconds)
        DateTime.strptime seconds.to_s, '%s'
      end
    end
  end
end

# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

class Mngt::StreamService
  Error = Class.new(StandardError)

  def initialize(user)
    @user   = user
    @secret = Mngt::Stream.api_secret
  end

  # Deterministic Stream user ID — prefixed to avoid conflicts with
  # any native Stream user namespace.
  def user_id
    "op_#{@user.id}"
  end

  # HS256 JWT signed with the Stream API secret.
  # Stream validates this server-side before accepting the connection.
  def user_token
    header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
    payload = Base64.urlsafe_encode64(
      { user_id: user_id, iat: Time.now.to_i - 1 }.to_json,
      padding: false
    )
    signing_input = "#{header}.#{payload}"
    signature = Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("SHA256", @secret, signing_input),
      padding: false
    )
    "#{signing_input}.#{signature}"
  end

  def user_data
    {
      id:   user_id,
      name: @user.name
    }
  end
end

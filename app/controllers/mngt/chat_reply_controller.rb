# frozen_string_literal: true

# Receives inline-reply POSTs from the service worker (notificationclick → action: 'reply').
# Authenticates via a short-lived HMAC-signed token included in the push payload.
class Mngt::ChatReplyController < ActionController::Base
  skip_forgery_protection

  def create
    token = params[:token].to_s
    text  = params[:text].to_s.strip
    return head :bad_request if token.blank? || text.blank?

    claims = verify_token(token)
    return head :unauthorized if claims.nil?
    return head :gone         if Time.now.to_i > claims["exp"].to_i

    user = User.find_by(id: claims["uid"])
    return head :not_found unless user

    Mngt::StreamChannelService.new(user).send_message(claims["ct"], claims["cid"], text)
    head :ok
  rescue Mngt::StreamChannelService::Error => e
    Rails.logger.warn("[Mngt::ChatReply] #{e.message}")
    head :bad_gateway
  end

  private

  def verify_token(token)
    b64, sig = token.split(".", 2)
    return nil if b64.blank? || sig.blank?

    secret   = Mngt::Stream.api_secret
    expected = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", secret, b64), padding: false)
    return nil unless ActiveSupport::SecurityUtils.secure_compare(expected, sig)

    JSON.parse(Base64.urlsafe_decode64(b64))
  rescue ArgumentError, JSON::ParserError
    nil
  end
end

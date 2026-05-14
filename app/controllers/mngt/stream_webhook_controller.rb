# frozen_string_literal: true

# Receives Stream webhook events (new.message, notification.message_new, etc.)
# and broadcasts to Action Cable so all connected clients poll immediately.
#
# Configure in Stream dashboard: Webhook URL → /mngt/stream/webhook
# Optionally set MNGT_STREAM_WEBHOOK_SECRET to enable signature verification.
class Mngt::StreamWebhookController < ActionController::Base
  skip_forgery_protection

  def receive
    return head :unauthorized unless valid_signature?

    ActionCable.server.broadcast("mngt_chat", { event: "activity" })
    head :ok
  end

  private

  def valid_signature?
    expected_secret = ENV["MNGT_STREAM_WEBHOOK_SECRET"]
    return true if expected_secret.blank?

    # Stream signs the payload with HMAC-SHA256 using the webhook secret.
    provided = request.headers["X-Signature"]
    return false if provided.blank?

    digest = OpenSSL::HMAC.hexdigest("SHA256", expected_secret, request.raw_post)
    ActiveSupport::SecurityUtils.secure_compare(digest, provided)
  end
end

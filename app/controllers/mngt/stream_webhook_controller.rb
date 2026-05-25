# frozen_string_literal: true

# Receives Stream webhook events and dispatches async push notification jobs.
# Configure in Stream dashboard: Webhook URL → /mngt/stream/webhook
# Optionally set MNGT_STREAM_WEBHOOK_SECRET to enable signature verification.
class Mngt::StreamWebhookController < ActionController::Base
  skip_forgery_protection

  def receive
    return head :unauthorized unless valid_signature?

    if Mngt::Vapid.configured?
      payload = JSON.parse(request.raw_post)
      enqueue_push(payload) if payload["type"] == "message.new"
    end

    head :ok
  rescue JSON::ParserError, StandardError => e
    Rails.logger.warn("[Mngt::Webhook] receive error: #{e.message}")
    head :ok
  end

  private

  def valid_signature?
    expected_secret = ENV["MNGT_STREAM_WEBHOOK_SECRET"]
    if expected_secret.blank?
      Rails.logger.warn("[Mngt::Webhook] MNGT_STREAM_WEBHOOK_SECRET is not set — signature verification disabled")
      return true
    end

    provided = request.headers["X-Signature"]
    return false if provided.blank?

    digest = OpenSSL::HMAC.hexdigest("SHA256", expected_secret, request.raw_post)
    ActiveSupport::SecurityUtils.secure_compare(digest, provided)
  end

  def enqueue_push(payload)
    msg     = payload["message"] || {}
    sender  = msg.dig("user", "id").to_s
    author  = msg.dig("user", "name").presence || "Alguém"
    text    = (msg["text"] || "").truncate(100)
    ch_type = payload["channel_type"].to_s
    ch_id   = (payload.dig("channel", "id") || payload["channel_id"]).to_s
    title   = ch_type == "messaging" ? author : (payload.dig("channel", "name").presence || "Chat")
    tag     = "mngt-#{ch_type}-#{ch_id}"

    raw_icon = msg.dig("user", "image").to_s
    icon_url = if raw_icon.start_with?("http")
                 raw_icon
               elsif raw_icon.start_with?("/")
                 "#{Setting.protocol}://#{Setting.host_name}#{raw_icon}"
               end

    members = extract_members(payload, sender)

    Rails.logger.info("[Mngt::Webhook] message.new from=#{sender} ch=#{ch_type}:#{ch_id} recipients=#{members.size}")

    # If members list was present in the payload, dispatch immediately.
    # If empty (Stream omits it on subsequent messages), let the job do the API fetch.
    Mngt::SendChatPushJob.perform_later(
      member_stream_ids: members,
      sender:,
      author:,
      text:,
      ch_type:,
      ch_id:,
      title:,
      tag:,
      icon_url:
    )
  end

  def extract_members(payload, sender)
    members = (payload["members"] || [])
              .map { |m| m.dig("user_id") || m.dig("user", "id") }
              .compact
              .map(&:to_s)
    members -= [sender]
    members
  end
end

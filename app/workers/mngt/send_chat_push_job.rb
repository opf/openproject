# frozen_string_literal: true

module Mngt
  # Delivers Web Push notifications for a Stream chat message.
  # Runs asynchronously so the webhook handler returns immediately.
  class SendChatPushJob < ApplicationJob
    queue_as :default

    def perform(member_stream_ids:, sender:, author:, text:, ch_type:, ch_id:,
                title:, tag:, icon_url:)
      return unless Mngt::Vapid.configured?

      # Stream omits members on subsequent messages in active channels — fetch if needed
      recipients = member_stream_ids.presence || fetch_channel_members(ch_type, ch_id) - [sender]
      return if recipients.empty?

      # Resolve all recipients in one query
      op_ids = recipients
                 .select { |id| id.to_s.start_with?("op_") }
                 .map    { |id| id.to_s.delete_prefix("op_").to_i }
      return if op_ids.empty?

      User.where(id: op_ids).find_each do |user|
        reply_token = generate_reply_token(user.id, ch_type, ch_id)
        Mngt::WebPushService.notify_user(
          user,
          title:,
          body:        "#{author}: #{text}",
          url:         "/?chat=#{ch_id}",
          icon:        icon_url,
          tag:,
          reply_token:,
          author:,
          text:,
          ch_type:
        )
      end
    end

    private

    def fetch_channel_members(ch_type, ch_id)
      header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
      pl      = Base64.urlsafe_encode64({ server: true }.to_json, padding: false)
      input   = "#{header}.#{pl}"
      sig     = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", Mngt::Stream.api_secret, input), padding: false)
      token   = "#{input}.#{sig}"

      uri = URI("https://chat.stream-io-api.com/channels/#{ch_type}/#{ch_id}/query")
      uri.query = URI.encode_www_form("api_key" => Mngt::Stream.api_key)

      req = Net::HTTP::Post.new(uri)
      req["Authorization"]    = token
      req["stream-auth-type"] = "jwt"
      req["Content-Type"]     = "application/json"
      req.body = { state: true, messages: { limit: 0 }, members: { limit: 100 }, watchers: { limit: 0 } }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) { |h| h.request(req) }
      JSON.parse(res.body).fetch("members", []).map { |m| m["user_id"] || m.dig("user", "id") }.compact.map(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("[Mngt::SendChatPush] fetch_channel_members error: #{e.message}")
      []
    end

    def generate_reply_token(user_id, channel_type, channel_id)
      secret = Mngt::Stream.api_secret
      exp    = (Time.now + 24.hours).to_i
      b64    = Base64.urlsafe_encode64(
        { uid: user_id, ct: channel_type, cid: channel_id, exp: }.to_json,
        padding: false
      )
      sig = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", secret, b64), padding: false)
      "#{b64}.#{sig}"
    end
  end
end

# frozen_string_literal: true

require "webpush"

class Mngt::WebPushService
  def self.notify_user(user, title:, body:, url: "/", icon: nil, tag: nil, reply_token: nil,
                       author: nil, text: nil, ch_type: nil)
    return unless Mngt::Vapid.configured?

    subs = Mngt::PushSubscription.where(user:)
    return if subs.none?

    payload = { title:, body:, url: }
    payload[:icon]        = icon        if icon.present?
    payload[:tag]         = tag         if tag.present?
    payload[:reply_token] = reply_token if reply_token.present?
    payload[:author]      = author      if author.present?
    payload[:text]        = text        if text.present?
    payload[:ch_type]     = ch_type     if ch_type.present?

    subs.find_each do |sub|
      Webpush.payload_send(
        message:  payload.to_json,
        endpoint: sub.endpoint,
        p256dh:   sub.p256dh,
        auth:     sub.auth,
        vapid: {
          subject:     "mailto:#{Setting.mail_from.presence || 'admin@example.com'}",
          public_key:  Mngt::Vapid.public_key,
          private_key: Mngt::Vapid.private_key
        },
        ttl: 86_400
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
      sub.destroy
    rescue StandardError => e
      Rails.logger.warn("[Mngt::WebPush] failed for sub #{sub.id}: #{e.message}")
    end
  end
end

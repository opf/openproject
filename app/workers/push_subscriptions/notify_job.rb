# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Wakes a user's installed browsers when they gain unread notifications.
#
# The push carries no content. It is an empty, VAPID-signed POST to each
# device's push service endpoint; the service worker then fetches the unread
# count over the user's own session and shows the notification itself.
#
# == Flow
#
# 1. A notification becoming unread schedules the job one debounce window out.
#    Further events for the same user inside that window are dropped, so a burst
#    yields one wake-up.
# 2. At delivery the job re-checks the user: push enabled, account active,
#    reminders not paused today, something still unread. A user who read the
#    notification in the meantime gets no wake-up.
# 3. Each subscription is posted to once. The push service collapses undelivered
#    wake-ups per topic while a device is offline.
#
# == Response handling
#
# * 2xx        the subscription is kept and touched
# * 404, 410   the endpoint is gone; the subscription is deleted
# * 429, 5xx, timeouts, DNS or socket errors
#              transient; the failed subscriptions are retried with polynomial
#              backoff, or after the server's Retry-After when that is longer,
#              up to MAX_ATTEMPTS, as a separate job that does not block the next
#              debounce window
# * other 4xx  logged and left alone; the user can re-subscribe from My account
#
# Deactivated and deleted users lose their subscriptions here as well as through
# the model callbacks, so a job that outlives the account cleans up after it.
class PushSubscriptions::NotifyJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  DEBOUNCE = 10.seconds
  MAX_ATTEMPTS = 4
  MAX_RETRY_DELAY = 1.hour
  # Apple rejects a topic whose length is 4n+1, which is not a valid unpadded base64url length.
  TOPIC = "openproject-unread"

  queue_with_priority :notification

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    key: -> { [self.class.name, *arguments].join("-") }
  )

  Retry = Data.define(:server_delay)

  TRANSIENT_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout,
    SsrfFilter::UnresolvedHostname, SystemCallError, SocketError, IOError,
    OpenSSL::SSL::SSLError, Net::ProtocolError, Net::HTTPBadResponse
  ].freeze

  def self.schedule_for(user_id)
    return unless OpenProject::WebPush.enabled? && PushSubscription.exists?(user_id:)

    set(wait: DEBOUNCE).perform_later(user_id)
  end

  def perform(user_id, subscription_ids = nil, attempt = 1)
    return unless OpenProject::WebPush.enabled?

    user = User.find_by(id: user_id)

    if user.nil? || !user.active?
      PushSubscription.where(user_id:).delete_all
      return
    end

    deliver_all(user, subscription_ids, attempt) if wakeable?(user)
  rescue OpenProject::WebPush::UnreadableKey => e
    OpenProject.logger.error("Browser notifications are paused: #{e.message}")
  end

  private

  def deliver_all(user, subscription_ids, attempt)
    subscriptions = user.push_subscriptions.order(:id)
    subscriptions = subscriptions.where(id: subscription_ids) if subscription_ids
    retries = subscriptions.map { [it.id, deliver(it)] }.select { |_, outcome| outcome.is_a?(Retry) }
    return if retries.empty?

    server_delay = retries.filter_map { |_, outcome| outcome.server_delay }.max
    retry_later(user.id, retries.map(&:first), attempt, server_delay)
  end

  def retry_later(user_id, subscription_ids, attempt, server_delay)
    if attempt >= MAX_ATTEMPTS
      Rails.logger.warn("Giving up on push wake-up for user #{user_id} after repeated transient failures")
      return
    end

    backoff = determine_delay(seconds_or_duration_or_algorithm: :polynomially_longer, executions: attempt).seconds
    wait = [[backoff, server_delay&.seconds].compact.max, MAX_RETRY_DELAY].min
    self.class.set(wait:).perform_later(user_id, subscription_ids, attempt + 1)
  end

  def wakeable?(user)
    !user.pref.reminders_paused_on?(user.today) &&
      Notification.visible(user).exists?(read_ian: false)
  end

  def deliver(subscription)
    response = OpenProject::SsrfProtection.post(
      subscription.endpoint,
      headers: headers_for(subscription),
      body: nil,
      http_options: { open_timeout: 5, read_timeout: 10 }
    )

    handle_response(subscription, response)
  rescue *TRANSIENT_ERRORS
    Retry.new(nil)
  rescue SsrfFilter::Error => e
    Rails.logger.warn("Push subscription #{subscription.id} rejected: #{e.class}")
  end

  def handle_response(subscription, response)
    code = response.code.to_i

    case code
    when 200..299 then subscription.touch
    when 404, 410 then subscription.destroy!
    when 429, 500..599 then Retry.new(retry_after(response))
    else
      Rails.logger.warn(
        "Push service #{URI(subscription.endpoint).host} answered #{code} for subscription #{subscription.id}"
      )
    end
  end

  def retry_after(response)
    value = response["Retry-After"].to_s.strip
    return value.to_i if value.match?(/\A\d+\z/)

    [Time.httpdate(value) - Time.current, 0].max
  rescue ArgumentError
    nil
  end

  def headers_for(subscription)
    ::WebPush::Request
      .new(message: nil,
           subscription: { endpoint: subscription.endpoint },
           vapid: { subject: OpenProject::WebPush.subject, pem: OpenProject::WebPush.vapid_key.to_pem },
           ttl: 3600,
           urgency: "low")
      .headers
      .merge("Topic" => TOPIC)
  end
end

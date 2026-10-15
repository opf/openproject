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
#              backoff, up to MAX_ATTEMPTS, as a separate job that does not block
#              the next debounce window
# * other 4xx  logged and left alone; the user can re-subscribe from My account
#
# Deactivated and deleted users lose their subscriptions here as well as through
# the model callbacks, so a job that outlives the account cleans up after it.
# A signed-out device keeps a dormant subscription without a session; it receives
# nothing until the next sign-in on that device binds it again.
class PushSubscriptions::NotifyJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  DEBOUNCE = 1.minute
  MAX_ATTEMPTS = 4
  # Apple rejects a topic whose length is 4n+1, which is not a valid unpadded base64url length.
  TOPIC = "openproject-unread"

  queue_with_priority :notification

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    key: -> { [self.class.name, *arguments].join("-") }
  )

  TRANSIENT_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout,
    SsrfFilter::UnresolvedHostname, SystemCallError, SocketError, IOError,
    OpenSSL::SSL::SSLError, Net::ProtocolError, Net::HTTPBadResponse
  ].freeze

  def self.schedule_for(user_id)
    return unless OpenProject::WebPush.enabled? && PushSubscription.active.exists?(user_id:)

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
    subscriptions = user.push_subscriptions.active.order(:id)
    subscriptions = subscriptions.where(id: subscription_ids) if subscription_ids
    failed_ids = subscriptions.filter_map { it.id if deliver(it) == :retry }

    retry_later(user.id, failed_ids, attempt) if failed_ids.any?
  end

  def retry_later(user_id, subscription_ids, attempt)
    if attempt >= MAX_ATTEMPTS
      Rails.logger.warn("Giving up on push wake-up for user #{user_id} after repeated transient failures")
      return
    end

    wait = determine_delay(seconds_or_duration_or_algorithm: :polynomially_longer, executions: attempt)
    self.class.set(wait: wait.seconds).perform_later(user_id, subscription_ids, attempt + 1)
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

    handle_response(subscription, response.code.to_i)
  rescue *TRANSIENT_ERRORS
    :retry
  rescue SsrfFilter::Error => e
    Rails.logger.warn("Push subscription #{subscription.id} rejected: #{e.class}")
  end

  def handle_response(subscription, code)
    case code
    when 200..299 then subscription.touch
    when 404, 410 then subscription.destroy!
    when 429, 500..599 then :retry
    else
      Rails.logger.warn(
        "Push service #{URI(subscription.endpoint).host} answered #{code} for subscription #{subscription.id}"
      )
    end
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

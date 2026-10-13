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

module Cron
  # Checks the open live updates subscriptions again, catching access changes without an event
  # (e.g. an expired session TTL, a session revoked by the user, or a permission changed outside
  # the services). Users who lost access reconnect, which checks their session and every
  # subscription again, rejecting what they lost and resuming the rest.
  class ReauthorizeLiveUpdatesJob < ApplicationJob
    include OpenProject::Authentication::SessionExpiration

    # Subscriptions of connections whose disconnect never reached Rails (e.g. anycable-go crashed)
    # are never removed otherwise. Their users reconnect, recording the live ones afresh.
    STALE_AFTER = 12.hours
    RECHECK_AFTER = 5.minutes

    # Rows of revoked streams stay until the disconnect unsubscribes their connections; until then they are rechecked.
    # Rows of stale subscriptions and ended sessions are removed here, as no valid unsubscribe may follow.
    def perform
      return unless OpenProject::LiveUpdates.enabled?

      expired = LiveUpdatesSubscription.where(created_at: ...STALE_AFTER.ago).or(subscriptions_of_ended_sessions)
      user_ids = expired.distinct.pluck(:user_id) | revoked_user_ids
      return if user_ids.empty?

      OpenProject::LiveUpdates.reauthorize(User.where(id: user_ids))
      expired.delete_all
    end

    private

    # The sessions row is touched on every session write, so it can be newer than the activity timestamp
    # in the session data that connect checks. Expired sessions may be caught a little late, never early.
    def subscriptions_of_ended_sessions
      sessions = Sessions::UserSession.all
      sessions = sessions.where(updated_at: session_ttl_minutes.ago..) if session_ttl_enabled?

      LiveUpdatesSubscription.where.not(session_id: sessions.select(:session_id))
    end

    def revoked_user_ids
      subscriptions_due = LiveUpdatesSubscription.where(updated_at: ...RECHECK_AFTER.ago)

      revoked = subscriptions_due
                   .select(:stream_name, :user_id).distinct.includes(:user)
                   .reject { |subscription| OpenProject::LiveUpdates.allowed?(subscription.stream_name, subscription.user) }
                   .map(&:user_id)
      subscriptions_due.touch_all
      revoked
    end
  end
end

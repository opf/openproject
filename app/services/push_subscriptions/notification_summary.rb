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

module PushSubscriptions
  class NotificationSummary
    LIMIT = 5
    ACTIVITY_AT = "COALESCE(journals.updated_at, notifications.created_at)"
    UPDATED_REASONS = %w[watched subscribed created processed prioritized scheduled].freeze

    def initialize(user)
      @user = user
    end

    def as_json(*)
      return { count: 0 } if groups.empty?

      { count: groups.first.unread_total, groups: groups.map { group_json(it) }, more: more_json }
    end

    private

    attr_reader :user

    def unread_visible
      Notification.visible(user).where(read_ian: false)
    end

    def latest_unread_per_work_package
      unread_visible
        .left_joins(:journal)
        .select(<<~SQL.squish)
          DISTINCT ON (notifications.resource_id) notifications.*,
          COUNT(*) OVER (PARTITION BY notifications.resource_id) AS unread_count,
          #{ACTIVITY_AT} AS activity_at
        SQL
        .order(Arel.sql("notifications.resource_id, #{ACTIVITY_AT} DESC, notifications.id DESC"))
    end

    def groups
      @groups ||= Notification
        .from(latest_unread_per_work_package, :notifications)
        .select("notifications.*, COUNT(*) OVER () AS work_package_count, (SUM(unread_count) OVER ())::integer AS unread_total")
        .order(activity_at: :desc, id: :desc)
        .limit(LIMIT)
        .preload(:actor, :resource)
        .to_a
    end

    def group_json(notification)
      work_package = notification.resource
      unread_count = notification.unread_count

      {
        tag: "openproject-#{user.id}-wp-#{work_package.id}",
        count: unread_count,
        revision: "#{notification.id}:#{(notification.activity_at.to_f * 1000).to_i}",
        title: unread_count > 1 ? I18n.t("pwa.push.group_title", count: unread_count) : headline(notification),
        body: body(notification, work_package, unread_count),
        url: url_helpers.details_notifications_path(work_package, tab: :activity)
      }
    end

    def body(notification, work_package, unread_count)
      if unread_count > 1
        "#{headline(notification)}: #{work_package.formatted_id} #{work_package.subject}"
      else
        "#{work_package.formatted_id}: #{work_package.subject}"
      end
    end

    def more_json
      remaining = groups.first.work_package_count - groups.size
      return if remaining.zero?

      { count: remaining, title: I18n.t("pwa.push.more_title", count: remaining), url: url_helpers.notifications_center_path }
    end

    def headline(notification)
      reason = UPDATED_REASONS.include?(notification.reason) ? "updated" : notification.reason
      actor_name = notification.actor&.name || I18n.t("user.deleted")
      I18n.t("pwa.push.reasons.#{reason}", actor: actor_name, default: I18n.t("pwa.push.reasons.updated", actor: actor_name))
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end

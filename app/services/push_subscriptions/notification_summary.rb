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
    UPDATED_REASONS = %w[watched subscribed created processed prioritized scheduled].freeze

    def initialize(user)
      @user = user
    end

    def as_json(*)
      return { count: 0 } if latest.nil?

      count > 1 ? summary : single
    end

    private

    attr_reader :user

    def unread
      Notification.visible(user).where(read_ian: false)
    end

    def count
      @count ||= unread.count
    end

    def latest
      @latest ||= unread.order(created_at: :desc, id: :desc).preload(:actor, :resource).first
    end

    def single
      { count:, title: headline, body: "#{work_package.formatted_id}: #{work_package.subject}", url: work_package_path }
    end

    def summary
      {
        count:,
        title: I18n.t("pwa.push.title", count:),
        body: "#{headline}: #{work_package.formatted_id} #{work_package.subject}",
        url: url_helpers.notifications_center_path
      }
    end

    def headline
      I18n.t("pwa.push.reasons.#{reason_key}", actor: actor_name)
    end

    def reason_key
      UPDATED_REASONS.include?(latest.reason) ? "updated" : latest.reason
    end

    def actor_name
      latest.actor&.name || I18n.t("user.deleted")
    end

    def work_package
      latest.resource
    end

    def work_package_path
      url_helpers.work_package_path(work_package)
    end

    def url_helpers
      OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end

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

module Groups::Concerns
  module MembershipManipulation
    extend ActiveSupport::Concern

    def after_validate(params, _call)
      params ||= {}

      with_error_handled do
        ::Group.transaction do
          send_notifications = params.fetch(:send_notifications, Journal::NotificationConfiguration.active?)
          exec_query!(params, send_notifications, params[:message])
        end
      end
    end

    private

    def with_error_handled
      yield
      ServiceResult.success result: model
    rescue StandardError => e
      Rails.logger.error do
        "Failed to modify members and associated roles of group #{model.id}: " \
          "#{e}\n#{e.backtrace.first(5).join("\n")}"
      end
      ServiceResult.failure(message: I18n.t(:notice_internal_server_error, app_title: Setting.app_title))
    end

    def exec_query!(params, send_notifications, message)
      affected_member_ids = modify_members_and_roles(params)

      touch_updated(affected_member_ids)

      if affected_member_ids.any? && send_notifications && Journal::NotificationConfiguration.active?
        send_notifications(affected_member_ids, message)
      end
    end

    def modify_members_and_roles(_params)
      raise NotImplementedError
    end

    def execute_query(query)
      ::Group
        .connection
        .exec_query(query)
        .rows
        .flatten
    end

    def touch_updated(member_ids)
      Member
        .where(id: member_ids)
        .touch_all
    end

    def send_notifications(member_ids, message)
      Notifications::GroupMemberAlteredJob.perform_later(
        User.current,
        member_ids,
        message,
        true
      )
    end
  end
end

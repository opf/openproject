#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Members::UpdateService < BaseServices::Update
  include Members::Concerns::CleanedUp
  include Members::Concerns::NotificationSender

  around_call :post_process

  private

  def post_process
    service_call = yield

    return unless service_call.success?

    member = service_call.result

    if member.principal.is_a?(Group)
      update_group_roles(member)
    else
      send_notification(member)
    end
  end

  def update_group_roles(member)
    Groups::UpdateRolesService
      .new(member.principal, current_user: user, contract_class: EmptyContract)
      .call(member:, send_notifications: send_notifications?, message: notification_message)
  end

  def event_type
    OpenProject::Events::MEMBER_UPDATED
  end
end

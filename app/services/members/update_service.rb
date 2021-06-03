#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Members::UpdateService < ::BaseServices::Update
  include Members::Concerns::CleanedUp

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

  def send_notification(member)
    OpenProject::Notifications.send(OpenProject::Events::MEMBER_UPDATED,
                                    member: member,
                                    message: notification_message)
  end

  def update_group_roles(member)
    Groups::UpdateRolesService
      .new(member.principal, current_user: user, contract_class: EmptyContract)
      .call(member: member, send_notifications: true, message: notification_message)
  end

  def set_attributes_params(params)
    super.except(:notification_message)
  end

  def notification_message
    params[:notification_message]
  end
end

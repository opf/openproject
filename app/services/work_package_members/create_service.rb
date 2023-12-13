# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

class WorkPackageMembers::CreateService < BaseServices::Create
  private

  def instance_class
    Member
  end

  def after_perform(service_call)
    return service_call unless service_call.success?

    work_package_member = service_call.result

    add_group_memberships(work_package_member)
    send_notification(work_package_member)

    service_call
  end

  def add_group_memberships(work_package_member)
    return unless work_package_member.principal.is_a?(Group)

    Groups::CreateInheritedRolesService
      .new(work_package_member.principal,
           current_user: user,
           contract_class: EmptyContract)
      .call(user_ids: work_package_member.principal.user_ids,
            send_notifications: false,
            project_ids: [work_package_member.project_id])
  end

  def send_notification(work_package_member)
    OpenProject::Notifications.send(OpenProject::Events::WORK_PACKAGE_SHARED,
                                    work_package_member:,
                                    send_notifications: true)
  end
end

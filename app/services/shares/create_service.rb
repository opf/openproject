# -- copyright
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
# ++

class Shares::CreateService < BaseServices::Create
  private

  def instance_class
    Member
  end

  def after_perform(service_call)
    return service_call unless service_call.success?

    share = service_call.result

    add_group_memberships(share)
    send_notification(share)

    service_call
  end

  def add_group_memberships(share)
    return unless share.principal.is_a?(Group)

    Groups::CreateInheritedRolesService
      .new(share.principal, current_user: user, contract_class: EmptyContract)
      .call(user_ids: share.principal.user_ids,
            send_notifications: false,
            project_ids: [share.project_id]) # TODO: Here we should add project_id and the entity id as well
  end

  def send_notification(share)
    return unless share.entity.is_a?(WorkPackage)

    OpenProject::Notifications.send(OpenProject::Events::WORK_PACKAGE_SHARED,
                                    work_package_member: share,
                                    send_notifications: true)
  end
end

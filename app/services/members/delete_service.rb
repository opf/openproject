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

class Members::DeleteService < BaseServices::Delete
  include Members::Concerns::CleanedUp

  def destroy(object)
    if object.member_roles.where.not(inherited_from: nil).empty?
      super
    else
      object.member_roles.where(inherited_from: nil).destroy_all
    end
  end

  protected

  def after_perform(service_call)
    super.tap do |call|
      member = call.result

      cleanup_for_group(member)
      send_notification(member) if member.destroyed?
    end
  end

  def send_notification(member)
    ::OpenProject::Notifications.send(OpenProject::Events::MEMBER_DESTROYED,
                                      member:)
  end

  def cleanup_for_group(member)
    return unless member.principal.is_a?(Group)

    Groups::CleanupInheritedRolesService
      .new(member.principal, current_user: user, contract_class: EmptyContract)
      .call
  end
end

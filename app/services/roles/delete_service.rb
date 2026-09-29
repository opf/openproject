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

class Roles::DeleteService < BaseServices::Delete
  def persist(service_result)
    # after destroy permissions can not be reached
    @permissions = model.permissions

    remove_memberships

    super
  end

  protected

  def after_perform(service_call)
    super.tap do |_call|
      ::OpenProject::Notifications.send(
        ::OpenProject::Events::ROLE_DESTROYED,
        permissions: @permissions
      )
    end
  end

  private

  def remove_memberships
    member_ids_holding_role.each do |member_id|
      member = Member.find_by(id: member_id)

      # Removing the role from a group cascades into the memberships inheriting it,
      # so those may already be gone or stripped of the role by the time we get here.
      next if member.nil? || member.role_ids.exclude?(model.id)

      remove_role_from(member)
    end
  end

  def member_ids_holding_role
    MemberRole.where(role_id: model.id).distinct.pluck(:member_id)
  end

  def remove_role_from(member)
    remaining_role_ids = member.role_ids - [model.id]

    if remaining_role_ids.empty?
      Members::DeleteService
        .new(user:, model: member, contract_class: EmptyContract)
        .call
    else
      Members::UpdateService
        .new(user:, model: member, contract_class: EmptyContract)
        .call(role_ids: remaining_role_ids)
    end
  end
end

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

class Members::CreateService < BaseServices::Create
  include Members::Concerns::NotificationSender

  around_call :post_process

  def post_process
    service_call = yield

    return unless service_call.success?

    member = service_call.result

    add_group_memberships(member)
    send_notification(member)
  end

  protected

  # When a Group is being added as a member to a project, an inherited Member
  # may already exist (created by ancestor group membership propagation).
  # In that case, find the existing member so we add direct roles to it
  # rather than failing on the uniqueness constraint.
  def instance(params)
    principal = params[:principal]
    if principal.is_a?(Group)
      Member.find_or_initialize_by(
        user_id: principal.id,
        project_id: params[:project_id],
        entity_type: params[:entity_type],
        entity_id: params[:entity_id]
      )
    else
      super
    end
  end

  def add_group_memberships(member)
    return unless member.principal.is_a?(Group)

    group = member.principal
    project_ids = member.project_id.nil? ? nil : [member.project_id]
    principal_ids = inheritable_principal_ids(group)

    Groups::CreateInheritedRolesService
      .new(group, current_user: user, contract_class: EmptyContract)
      .call(user_ids: principal_ids, send_notifications: false, project_ids:)
  end

  def inheritable_principal_ids(group)
    group_ids = group.descendants.pluck(:id)
    user_ids = group.self_and_descendants.flat_map(&:user_ids).uniq

    (user_ids + group_ids).uniq
  end

  def event_type
    OpenProject::Events::MEMBER_CREATED
  end
end

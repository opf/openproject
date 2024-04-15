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

class Mails::MemberJob < ApplicationJob
  queue_with_priority :notification

  def perform(current_user:,
              member:,
              message: nil)
    case member.principal
    when Group
      perform_for_group(current_user:, member:, message:)
    when User
      perform_for_user(current_user:, member:, message:)
    end
  end

  private

  def perform_for_group(current_user:,
                        member:,
                        message: nil)
    every_group_user_member(member) do |user_member|
      if member.project.nil?
        next unless roles_changed?(user_member, member)

        send_updated_global(current_user, user_member, message)
      else
        send_for_group_user(current_user, user_member, member, message)
      end
    end
  end

  def perform_for_user(current_user:,
                       member:,
                       message: nil)
    if member.project.nil?
      send_updated_global(current_user, member, message)
    else
      send_for_project_user(current_user, member, message)
    end
  end

  def send_for_group_user(_current_user, _member, _group, _message)
    raise NotImplementedError, "subclass responsibility"
  end

  def send_for_project_user(_current_user, _member, _message)
    raise NotImplementedError, "subclass responsibility"
  end

  def send_updated_global(current_user, member, member_message)
    return if sending_disabled?(:updated, current_user, member.user_id, member_message)

    MemberMailer
      .updated_global(current_user, member, member_message)
      .deliver_now
  end

  def send_added_project(current_user, member, member_message)
    return if sending_disabled?(:added, current_user, member.user_id, member_message)

    MemberMailer
      .added_project(current_user, member, member_message)
      .deliver_now
  end

  def send_updated_project(current_user, member, member_message)
    return if sending_disabled?(:updated, current_user, member.user_id, member_message)

    MemberMailer
      .updated_project(current_user, member, member_message)
      .deliver_now
  end

  def every_group_user_member(member, &)
    Member
      .of_project(member.project)
      .where(principal: member.principal.users)
      .includes(:project, :principal, :roles, :member_roles)
      .each(&)
  end

  def sending_disabled?(setting, current_user, user_id, message)
    # Never self notify
    return true if current_user.id == user_id
    # In case we have an invitation message, always send a mail
    return false if message.present?

    NotificationSetting
      .where(project_id: nil, user_id:)
      .exists?("membership_#{setting}" => false)
  end

  def roles_changed?(user_member, group_member)
    Members::RolesDiff.new(user_member, group_member).roles_changed?
  end
end

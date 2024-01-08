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

class Mails::WorkPackageSharedJob < ApplicationJob
  queue_with_priority :notification

  def perform(current_user:,
              work_package_member:)
    case work_package_member.principal
    when Group
      perform_for_group(current_user:, work_package_member:)
    when User
      perform_for_user(current_user:, work_package_member:)
    end
  end

  private

  def perform_for_group(current_user:, work_package_member:)
    group_user_members(work_package_member:).each do |user_member|
      perform_for_user(current_user:, work_package_member: user_member)
    end
  end

  def perform_for_user(current_user:, work_package_member:)
    SharingMailer
      .shared_work_package(current_user, work_package_member)
      .deliver_now
  end

  def group_user_members(work_package_member:)
    Member.where(id: newly_invited_group_user_member_ids(work_package_member:))
  end

  # Given invitation mails are only sent out on the first invitation, we can
  # query on whether a user should be sent a mail or not by checking whether
  # there is a single member_role for the member. If there is, the
  # user has no other current shares on the work package (via a group or independently)
  # and should be sent a mail.
  def newly_invited_group_user_member_ids(work_package_member:)
    Member.of_work_package(work_package_member.entity)
          .joins(:member_roles)
          .references(:member_roles)
          .where(principal: work_package_member.principal.users)
          .group('members.id')
          .having("COUNT(*) = 1")
          .select('members.id')
  end
end

# frozen_string_literal: true

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

class SharingMailerPreview < ActionMailer::Preview
  def shared_work_package
    sharer = User.first
    work_package_membership = Member.where(entity_type: "WorkPackage").first

    SharingMailer.shared_work_package(sharer, work_package_membership)
  end

  def shared_work_package_via_group
    sharer = User.first
    group = Group.first
    user_membership = Member.find_by(entity_type: "WorkPackage", principal: group.users.first)

    SharingMailer.shared_work_package(sharer, user_membership, group)
  end

  def shared_work_package_via_invitation
    sharer = User.first
    work_package_membership = Member.includes(:principal)
                                    .where(entity_type: "WorkPackage")
                                    .where(principal: { status: :invited })
                                    .first

    SharingMailer.shared_work_package(sharer, work_package_membership)
  end
end

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

class Mails::Deliver::MemberCreatedJob < ApplicationJob
  def perform(current_user:,
              member:)
    # TODO: add a Mails::Prepare::MemberCreatedJob that fans out the member in case the principal
    # is a group which will result in multiple memberships being added
    # In order to determine whether user was added to the project
    # by the group, compare updated_at and created_at. If they differ,
    # the membership was updated. If they are the same, the membership was created.
    # DISCUSS: do we want to handle the fan out in a delayed job. I think we do.
    # DISCUSS: do we want to create individual delayed jobs for every fanned out job. I think we don't.
    # TODO: also cover adding a user to a group
    if member.project.nil?
      MemberMailer
        .updated_global(current_user, member)
        .deliver_now
    elsif member.principal.is_a?(Group)
      Member
        .of(member.project)
        .where(principal: member.principal.users)
        .includes(:project, :principal, :roles)
        .each do |users_member|
        # TODO: differentiate between the user having just been added as a member and a user
        # having gained additional permissions
        # Because the user could already have been a member before the group adds additional ones
        MemberMailer
          .added_project(current_user, users_member)
          .deliver_now
      end
    elsif member.principal.is_a?(User)
      MemberMailer
        .added_project(current_user, member)
        .deliver_now
    end
  end
end

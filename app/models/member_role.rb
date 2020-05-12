#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class MemberRole < ApplicationRecord
  belongs_to :member
  belongs_to :role

  after_create :add_role_to_group_users
  after_destroy :remove_role_from_group_users

  validates_presence_of :role
  validate :validate_project_member_role

  def validate_project_member_role
    errors.add :role_id, :invalid if role && !role.member?
  end

  # Add alias, so Member can still destroy MemberRoles
  # Don't call this from anywhere else, use remove_member_role on Member.
  alias :destroy_for_member :destroy

  # You shouldn't call this, only ActiveRecord itself is allowed to do this
  # when destroying a Member. Use Member.remove_member_role to remove a role from a member.
  #
  # You may remove this once we have a layer above persistence that handles business logic
  # and prevents or at least discourages working on persistence objects from controllers
  # or unrelated business logic.
  def destroy(*args)
    unless caller[2] =~ /has_many_association\.rb:[0-9]+:in `delete_records'/
      raise 'MemberRole.destroy called from method other than HasManyAssociation.delete_records' +
        "\n  on #{inspect}\n from #{caller.first} / #{caller[6]}"
    else
      super
    end
  end

  def inherited?
    !inherited_from.nil?
  end

  private

  def add_role_to_group_users
    if member && member.principal.is_a?(Group)
      member.principal.users.each do |user|
        user_member = Member.find_by(project_id: member.project_id, user_id: user.id)

        if user_member.nil?
          user_member = Member.new.tap do |m|
            m.project_id = member.project_id
            m.user_id = user.id
          end

          user_member.add_role(role, id)
          user_member.save
        else
          user_member.add_and_save_role(role, id)
        end
      end
    end
  end

  def remove_role_from_group_users
    inherited_roles_by_member = MemberRole
                                .where(inherited_from: id)
                                .includes(member: %i[principal member_roles])
                                .group_by(&:member)

    inherited_roles_by_member.each do |member, member_roles|
      member_roles.each do |mr|
        member.remove_member_role_and_destroy_member_if_last(mr, prune_watchers: false)
      end
    end

    users = inherited_roles_by_member.keys.map(&:principal)

    Watcher.prune(user: users, project_id: member.project_id) unless users.empty?
  end
end

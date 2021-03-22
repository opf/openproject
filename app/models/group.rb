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

class Group < Principal
  include ::Scopes::Scoped

  has_many :group_users,
           autosave: true,
           dependent: :destroy,
           after_remove: :user_removed

  has_many :users,
           through: :group_users,
           before_add: :fail_add

  acts_as_customizable

  alias_attribute(:name, :lastname)
  validates_presence_of :name
  validate :uniqueness_of_name
  validates_length_of :name, maximum: 256

  # HACK: We want to have the :preference association on the Principal to allow
  # for eager loading preferences.
  # However, the preferences are currently very user specific.  We therefore
  # remove the methods added by
  #   has_one :preference
  # to avoid accidental assignment and usage of preferences on groups.
  undef_method :preference,
               :preference=,
               :build_preference,
               :create_preference,
               :create_preference!

  include Destroy

  scopes :visible

  def to_s
    lastname
  end

  def user_removed(group_user)
    user = group_user.user

    member_roles = MemberRole
                   .includes(member: :member_roles)
                   .where(inherited_from: members.joins(:member_roles).select('member_roles.id'))
                   .where(members: { user_id: user.id })

    project_ids = member_roles.map { |mr| mr.member.project_id }

    member_roles.each do |member_role|
      member_role.member.remove_member_role_and_destroy_member_if_last(member_role,
                                                                       prune_watchers: false)
    end

    Watcher.prune(user: user, project_id: project_ids)
  end

  # adds group members
  # meaning users that are members of the group
  def add_members!(users)
    user_ids = Array(users).map { |user_or_id| user_or_id.is_a?(Integer) ? user_or_id : user_or_id.id }

    ::Groups::AddUsersService
      .new(self, current_user: User.current)
      .call(ids: user_ids)
      .tap do |result|
      raise "Failed to add to group #{result.message}" if result.failure?
    end
  end

  private

  def uniqueness_of_name
    groups_with_name = Group.where('lastname = ? AND id <> ?', name, id || 0).count
    if groups_with_name > 0
      errors.add :name, :taken
    end
  end

  def fail_add
    fail "Do not add users through association, use `group.add_members!` instead."
  end
end

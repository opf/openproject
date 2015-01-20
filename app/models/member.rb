#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Member < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :principal, foreign_key: 'user_id'
  has_many :member_roles, dependent: :destroy, autosave: true
  has_many :roles, through: :member_roles
  belongs_to :project

  validates_presence_of :project
  validates_uniqueness_of :user_id, scope: :project_id

  validate :validate_presence_of_role
  validate :validate_presence_of_principal

  before_destroy :remove_from_category_assignments
  after_destroy :unwatch_from_permission_change

  def name
    user.name
  end

  def to_s
    name
  end

  # Set the roles for this member to the given roles_or_role_ids.
  # Inherited roles are left untouched.
  def assign_roles(roles_or_role_ids)
    do_assign_roles(roles_or_role_ids, false)
  end

  alias :base_role_ids= :role_ids=

  # Set the roles for this member to the given roles_or_role_ids, immediately
  # save the changes and destroy the member in case no role is left.
  # Inherited roles are left untouched.
  def assign_and_save_roles_and_destroy_member_if_none_left(roles_or_role_ids)
    do_assign_roles(roles_or_role_ids, true)
  end
  alias_method :role_ids=, :assign_and_save_roles_and_destroy_member_if_none_left

  # Add a role to the membership
  # Does not save the changes, the member must be saved afterwards for the role to be added.
  def add_role(role_or_role_id, inherited_from_id = nil)
    do_add_role(role_or_role_id, inherited_from_id, false)
  end

  # Add a role and save the change to the database
  def add_and_save_role(role_or_role_id, inherited_from_id = nil)
    do_add_role(role_or_role_id, inherited_from_id, true)
  end

  # Mark one of the member's roles for destruction
  #
  # Make sure to get the MemberRole instance from the member's association, otherwise the actual
  # destruction on save doesn't work.
  def mark_member_role_for_destruction(member_role)
    do_remove_member_role(member_role, false)
  end

  # Remove a role from a member
  # Destroys the member itself when no role is left afterwards
  #
  # Make sure to get the MemberRole instance from the member's association, otherwise the
  # destruction of the member, when the last MemberRole is destroyed, might not work.
  def remove_member_role_and_destroy_member_if_last(member_role)
    do_remove_member_role(member_role, true)
  end

  def <=>(member)
    a, b = roles.sort.first, member.roles.sort.first
    a == b ? (principal <=> member.principal) : (a <=> b)
  end

  def deletable?
    member_roles.detect(&:inherited_from).nil?
  end

  def include?(user)
    if principal.is_a?(Group)
      !user.nil? && user.groups.include?(principal)
    else
      self.user == user
    end
  end

  # remove category based auto assignments for this member
  def remove_from_category_assignments
    Category.update_all 'assigned_to_id = NULL', ['project_id = ? AND assigned_to_id = ?', project.id, user.id] if user
  end

  # Find or initialize a Member with an id, attributes, and for a Principal
  def self.edit_membership(id, new_attributes, principal = nil)
    @membership = id.present? ? Member.find(id) : Member.new(principal: principal)
    # interface refactoring needed
    # not critical atm because only admins can invoke it (see users and groups controllers)
    @membership.force_attributes = new_attributes
    @membership
  end

  protected

  def destroy_if_no_roles_left!
    destroy if member_roles.empty? || member_roles.all? do |member_role|
      member_role.marked_for_destruction? || member_role.destroyed?
    end
  end

  def validate_presence_of_role
    if member_roles.empty?
      errors.add :base, :role_blank if roles.empty?
    else
      errors.add :base, :role_blank if member_roles.all? do |member_role|
        member_role.marked_for_destruction? || member_role.destroyed?
      end
    end
  end

  def validate_presence_of_principal
    errors.add :base, :principal_blank if principal.blank?
  end

  def do_add_role(role_or_role_id, inherited_from_id, save_immediately)
    id = (role_or_role_id.is_a? Role) ? role_or_role_id.id : role_or_role_id

    if save_immediately
      member_roles << MemberRole.new.tap do |member_role|
        member_role.role_id = id
        member_role.inherited_from = inherited_from_id
      end
    else
      member_roles.build.tap do |member_role|
        member_role.role_id = id
        member_role.inherited_from = inherited_from_id
      end
    end
  end

  # Set save_and_possibly_destroy to true to immediately save changes and destroy
  # when no roles are left.
  def do_assign_roles(roles_or_role_ids, save_and_possibly_destroy)
    # ensure we have integer ids
    ids = roles_or_role_ids.map { |r| (r.is_a? Role) ? r.id : r.to_i }

    # Keep inherited roles
    ids += member_roles.select { |mr| !mr.inherited_from.nil? }.map(&:role_id)

    new_role_ids = ids - role_ids
    # Add new roles
    # Do this before destroying them, otherwise the Member is destroyed due to not having any
    # Roles assigned via MemberRoles.
    new_role_ids.each { |id| do_add_role(id, nil, save_and_possibly_destroy) }

    # Remove roles (Rails' #role_ids= will not trigger MemberRole#on_destroy)
    member_roles_to_destroy = member_roles.select { |mr| !ids.include?(mr.role_id) }
    member_roles_to_destroy.each { |mr| do_remove_member_role(mr, save_and_possibly_destroy) }
  end

  def do_remove_member_role(member_role, destroy)
    if destroy
      member_role.destroy_for_member
      destroy_if_no_roles_left!
    else
      member_role.mark_for_destruction
    end
    unwatch_from_permission_change
  end

  private

  # Unwatch things that the user is no longer allowed to view inside project
  def unwatch_from_permission_change
    if user
      Watcher.prune(user: user, project: project)
    end
  end
end

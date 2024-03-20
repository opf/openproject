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

class Role < ApplicationRecord
  # Built-in roles
  NON_BUILTIN = 0
  BUILTIN_NON_MEMBER = 1
  BUILTIN_ANONYMOUS  = 2
  BUILTIN_WORK_PACKAGE_VIEWER = 3
  BUILTIN_WORK_PACKAGE_COMMENTER = 4
  BUILTIN_WORK_PACKAGE_EDITOR = 5

  scope :builtin, ->(*args) {
    compare = 'not' if args.first == true
    where("#{compare} builtin = #{NON_BUILTIN}")
  }

  # Work Package Roles are intentionally visually hidden from users temporarily
  scope :visible, -> { where.not(type: 'WorkPackageRole') }
  scope :ordered_by_builtin_and_position, -> { order(Arel.sql('builtin, position')) }

  before_destroy(prepend: true) do
    unless deletable?
      errors.add(:base, "can't be destroyed")
      raise ActiveRecord::RecordNotDestroyed
    end
  end

  has_many :workflows, dependent: :delete_all do
    def copy_from_role(source_role)
      Workflow.copy(nil, source_role, nil, proxy_association.owner)
    end
  end

  has_many :member_roles, dependent: :destroy
  has_many :members, through: :member_roles
  has_many :role_permissions, dependent: :destroy

  default_scope -> {
    includes(:role_permissions)
  }

  acts_as_list

  validates :name,
            presence: true,
            length: { maximum: 256 },
            uniqueness: { case_sensitive: true }

  # Turn this class into an abstract one by validating the STI column.
  validates :type,
            inclusion: { in: ->(*) { Role.subclasses.map(&:to_s) } }

  def self.givable
    where
      .not(
        builtin: [
          Role::BUILTIN_NON_MEMBER,
          Role::BUILTIN_ANONYMOUS,
          Role::BUILTIN_WORK_PACKAGE_VIEWER,
          Role::BUILTIN_WORK_PACKAGE_COMMENTER,
          Role::BUILTIN_WORK_PACKAGE_EDITOR
        ]
      )
      .order(Arel.sql('position'))
  end

  def permissions
    # prefer map over pluck as we will probably always load
    # the permissions anyway
    role_permissions.map { |perm| perm.permission.to_sym }
  end

  def permissions=(perms)
    not_included_yet = (perms.map(&:to_sym) - permissions).compact_blank
    included_until_now = permissions - perms.map(&:to_sym)

    remove_permission!(*included_until_now)

    add_permission!(*not_included_yet)
  end

  def add_permission!(*perms)
    perms.each do |perm|
      add_permission(perm)
    end
  end

  def remove_permission!(*perms)
    return unless permissions.is_a?(Array)

    perms = perms.map(&:to_s)

    self.role_permissions = role_permissions.reject do |rp|
      perms.include?(rp.permission)
    end
  end

  # Returns true if the role has the given permission
  def has_permission?(perm)
    !permissions.nil? && permissions.include?(perm.to_sym)
  end

  def <=>(other)
    other ? position <=> other.position : -1
  end

  def to_s
    name
  end

  # Return true if the role is a builtin role
  def builtin?
    builtin != NON_BUILTIN
  end

  # Return true if the role is a project member role
  def member?
    !builtin?
  end

  # Return true if role is allowed to do the specified action
  # action can be:
  # * a parameter-like Hash (eg. controller: '/projects', action: 'edit')
  # * a permission Symbol (eg. :edit_project)
  def allowed_to?(action)
    if action.is_a? Hash
      allowed_actions.include? "#{action[:controller]}/#{action[:action]}"
    else
      permissions.include? action
    end
  end

  def self.by_permission(permission)
    all.select do |role|
      role.allowed_to? permission
    end
  end

  def deletable?
    members.none? && !builtin?
  end

  private

  def allowed_actions
    @allowed_actions ||= permissions.flat_map do |permission|
      OpenProject::AccessControl.allowed_actions(permission)
    end
  end

  def add_permission(permission)
    if persisted?
      role_permissions.create(permission:)
    else
      role_permissions.build(permission:)
    end
  end
end

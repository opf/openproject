#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class Member < ApplicationRecord
  include ::Scopes::Scoped

  extend DeprecatedAlias
  belongs_to :principal, foreign_key: 'user_id'
  has_many :member_roles, dependent: :destroy, autosave: true, validate: false
  has_many :roles, -> { distinct }, through: :member_roles
  belongs_to :project

  validates :principal, presence: true
  validates :user_id, uniqueness: { scope: :project_id }

  validate :validate_presence_of_role
  validate :validate_presence_of_principal

  scopes :assignable,
         :global,
         :not_locked,
         :of,
         :visible

  delegate :name, to: :principal

  def to_s
    name
  end

  deprecated_alias :user, :principal
  deprecated_alias :user=, :principal=

  def <=>(other)
    a = roles.min
    b = other.roles.min
    a == b ? (principal <=> other.principal) : (a <=> b)
  end

  def deletable?
    member_roles.detect(&:inherited_from).nil?
  end

  def deletable_role?(role)
    member_roles
      .only_inherited
      .where(role:)
      .none?
  end

  def include?(principal)
    if user?
      self.principal == principal
    else
      !principal.nil? && principal.groups.include?(principal)
    end
  end

  ##
  # Returns true if this user can be deleted as they have no other memberships
  # and haven't been activated yet. Only applies if the member is actually a user
  # as opposed to a group.
  def disposable?
    user? && principal&.invited? && principal.memberships.none? { |m| m.project_id != project_id }
  end

  protected

  attr_accessor :prune_watchers_on_destruction

  def validate_presence_of_role
    if (member_roles.empty? && roles.empty?) ||
       member_roles.all? do |member_role|
         member_role.marked_for_destruction? || member_role.destroyed?
       end

      errors.add :roles, :role_blank
    end
  end

  def validate_presence_of_principal
    errors.add :base, :principal_blank if principal.blank?
  end

  private

  def user?
    principal.is_a?(User)
  end
end

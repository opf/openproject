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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class SecurityLevel < ApplicationRecord
  belongs_to :security_level_scheme, inverse_of: :security_levels
  has_many :security_level_principals, dependent: :delete_all
  has_many :principals, through: :security_level_principals
  has_many :work_packages, dependent: :nullify

  acts_as_list scope: :security_level_scheme_id

  validates :name,
            presence: true,
            uniqueness: { scope: :security_level_scheme_id, case_sensitive: false },
            length: { maximum: 255 }

  scope :of_principals, ->(principal_ids) {
    where(id: SecurityLevelPrincipal.where(principal_id: principal_ids).select(:security_level_id))
  }

  def self.ids_for(user)
    return [] unless user.is_a?(User) && user.logged?

    SecurityLevelPrincipal
      .where(principal_id: user.id)
      .or(SecurityLevelPrincipal.where(principal_id: GroupUser.where(user_id: user.id).select(:group_id)))
      .distinct
      .pluck(:security_level_id)
  end

  def self.bypassed_by?(user)
    user.admin?
  end

  def self.visible_to?(user, security_level_id)
    security_level_id.nil? || bypassed_by?(user) || user.security_level_ids.include?(security_level_id)
  end

  def self.hidden_work_packages_for(user)
    return WorkPackage.none if bypassed_by?(user)

    WorkPackage.where.not(security_level_id: nil).where.not(security_level_id: user.security_level_ids)
  end

  def to_s = name
end

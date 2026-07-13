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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Groups
  class BaseContract < ::ModelContract
    include RequiresAdminGuard

    # attribute_alias is broken in the sense
    # that `model#changed` includes only the non-aliased name
    # hence we need to put "lastname" as an attribute here
    attribute :name
    attribute :lastname
    attribute :parent_id

    validate :validate_unique_users
    validate :validate_users_not_in_other_department
    validate :validate_not_ldap_managed
    validate :validate_parent_not_ldap_managed

    private

    # Departments synchronized from LDAP are read-only: their name, parent and members are owned by
    # the sync. The sync itself bypasses this through Groups::SyncUpdateContract.
    def validate_not_ldap_managed
      errors.add(:base, :ldap_managed) if model.ldap_managed?
    end

    # A department managed by LDAP owns its sub-tree, so new or moved departments may not be nested
    # underneath one. The sync bypasses this through its permissive contracts.
    def validate_parent_not_ldap_managed
      return if model.parent_id.blank?

      parent = Group.find_by(id: model.parent_id)
      errors.add(:parent_id, :parent_ldap_managed) if parent&.ldap_managed?
    end

    # Validating on the group_users since those are dealt with in the
    # corresponding services.
    def validate_unique_users
      user_ids = model.group_users.map(&:user_id)

      if user_ids.uniq.length < user_ids.length
        errors.add(:group_users, :taken)
      end
    end

    def validate_users_not_in_other_department
      return unless model.organizational_unit?

      new_user_ids = model.group_users.select(&:new_record?).map(&:user_id)
      return if new_user_ids.empty?

      users_already_in_departments(new_user_ids).each do |user_id, department_id|
        errors.add(:group_users, :user_already_in_department, user_id:, department_id:)
      end
    end

    def users_already_in_departments(user_ids)
      GroupUser
        .joins(:group)
        .merge(Group.organizational_units)
        .where(user_id: user_ids)
        .where.not(group_id: model.id)
        .pluck(:user_id, :group_id)
    end
  end
end

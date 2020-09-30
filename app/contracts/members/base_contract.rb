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

module Members
  class BaseContract < ::ModelContract
    delegate :principal,
             :project,
             :new_record?,
             to: :model

    attribute :roles

    validate :user_allowed_to_manage
    validate :roles_grantable

    private

    def user_allowed_to_manage
      errors.add :base, :error_unauthorized unless user_allowed_to_manage?
    end

    def roles_grantable
      unmarked_roles = model.member_roles.reject(&:marked_for_destruction?).map(&:role)

      errors.add(:roles, :ungrantable) unless unmarked_roles.all? { |r| role_grantable?(r) }
    end

    def role_grantable?(role)
      role.builtin == Role::NON_BUILTIN &&
        ((model.project && role.class == Role) || (!model.project && role.class == GlobalRole))
    end

    def user_allowed_to_manage?
      (model.project && user.allowed_to?(:manage_members, model.project)) ||
        (!model.project && user.admin?)
    end
  end
end

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

module Users
  # Password-login policy: who may authenticate with a local (or LDAP) password.
  #
  # Modes:
  # * +all+ — anyone with a password
  # * +except_sso+ — Users that are not connected to an SSO auth provider
  # * +none+ — Only users on the allowlist may use their internal password
  module PasswordLogin
    ALL = "all"
    EXCEPT_SSO = "except_sso"
    NONE = "none"
    MODES = [ALL, EXCEPT_SSO, NONE].freeze

    module_function

    def mode
      value = Setting.password_login
      MODES.include?(value) ? value : ALL
    end

    def all? = mode == ALL
    def except_sso? = mode == EXCEPT_SSO
    def none? = mode == NONE
    def enabled? = !none?
    def restricted? = !all?

    def allowed?(user)
      return true if bypass?(user)

      case mode
      when EXCEPT_SSO then !user.uses_external_authentication?
      when NONE then false
      else true
      end
    end

    def bypass?(user)
      return false if user.blank?

      bypassed_user_ids.include?(user.id) || login_bypassed?(user)
    end

    def internal_login_available?
      none? && (bypass_principal_ids.any? || bypass_logins.any?)
    end

    def omniauth_configured?
      AuthProvider.exists?(available: true)
    end

    def bypass_principal_ids
      Array(Setting.password_login_bypass_principal_ids).filter_map { |id| Integer(id, exception: false) }
    end

    def bypass_logins
      Array(Setting.password_login_bypass_logins).compact_blank.map(&:to_s)
    end

    def bypassed_user_ids
      (
        User.where(id: bypass_principal_ids).pluck(:id) +
          User.by_logins(bypass_logins).pluck(:id) +
          GroupUser.where(group_id: expanded_group_ids).pluck(:user_id)
      ).uniq
    end

    def expanded_group_ids
      Group.where(id: bypass_principal_ids).flat_map { |group| group.self_and_descendants.ids }.uniq
    end

    def login_bypassed?(user)
      login = user.login
      return false if login.blank?

      bypass_logins.any? { |exempt| exempt.casecmp?(login) }
    end
  end
end

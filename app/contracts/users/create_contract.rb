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

module Users
  class CreateContract < BaseContract
    attribute :type

    attribute :status do
      unless model.active? || model.invited?
        # New users may only have these two statuses
        errors.add :status, :invalid_on_create
      end
    end

    validate :user_allowed_to_add
    validate :authentication_defined
    validate :type_is_user
    validate :user_limit_not_exceeded
    validate :notification_settings_present

    private

    def user_limit_not_exceeded
      if OpenProject::Enterprise.user_limit_reached?
        errors.add :base, :user_limit_reached
      end
    end

    def notification_settings_present
      if model.notification_settings.empty?
        errors.add :notification_settings, :blank
      end
    end

    def authentication_defined
      errors.add :password, :blank if model.active? && no_auth?
    end

    def no_auth?
      model.password.blank? && model.ldap_auth_source_id.blank? && model.identity_url.blank?
    end

    ##
    # Users can only be created by Admins or users with
    # the global right to :create_user
    def user_allowed_to_add
      unless user.allowed_globally?(:create_user)
        errors.add :base, :error_unauthorized
      end
    end

    def type_is_user
      unless model.type == User.name
        errors.add(:type, 'Type and class mismatch')
      end
    end
  end
end

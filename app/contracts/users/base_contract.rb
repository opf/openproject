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
  class BaseContract < ::ModelContract
    include AssignableCustomFieldValues

    attribute :login,
              writable: ->(*) {
                can_create_or_manage_users? && model.id != user.id
              }
    attribute :firstname
    attribute :lastname
    attribute :mail
    attribute :admin,
              writable: ->(*) { user.admin? && model.id != user.id }
    attribute :language

    attribute :ldap_auth_source_id,
              writable: ->(*) { can_create_or_manage_users? }

    attribute :status,
              writable: ->(*) { can_create_or_manage_users? }

    attribute :identity_url,
              writable: ->(*) { user.admin? }

    attribute :force_password_change,
              writable: ->(*) { user.admin? }

    def self.model
      User
    end

    validate :validate_password_writable
    validate :existing_auth_source

    delegate :available_custom_fields, to: :model

    def reduce_writable_attributes(attributes)
      super.tap do |writable|
        writable << 'password' if password_writable?
      end
    end

    private

    ##
    # Password is not a regular attribute so it bypasses
    # attribute writable checks
    def password_writable?
      user.admin? || user.id == model.id
    end

    ##
    # User#password is not an ActiveModel property,
    # but just an accessor, so we need to identify it being written there.
    # It is only present when freshly written
    def validate_password_writable
      # Only admins or the user themselves can set the password
      return if password_writable?

      errors.add :password, :error_readonly if model.password.present?
    end

    # rubocop:disable Rails/DynamicFindBy
    def existing_auth_source
      if ldap_auth_source_id && LdapAuthSource.find_by_unique(ldap_auth_source_id).nil?
        errors.add :auth_source, :error_not_found
      end
    end
    # rubocop:enable Rails/DynamicFindBy

    def can_create_or_manage_users?
      user.allowed_globally?(:manage_user) || user.allowed_globally?(:create_user)
    end
  end
end

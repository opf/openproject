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
  class BaseContract < ::ModelContract
    include AssignableCustomFieldValues

    attribute :login,
              writable: ->(*) {
                can_create_or_manage_users? && !editing_self?
              }
    attribute :firstname, writable: ->(*) { can_create_or_manage_users? || can_change_self? }
    attribute :lastname, writable: ->(*) { can_create_or_manage_users? || can_change_self? }
    attribute :mail,
              # We restrict email changes to admins (not :manage_user role), to prevent privilege escalation
              # Escalation path: change email of user with desired permissions to own email -> reset password -> login as user
              writable: ->(*) { model.new_record? || user.admin? || can_change_self? }
    attribute :admin,
              writable: ->(*) { user.admin? && !editing_self? }
    attribute :language

    attribute :ldap_auth_source_id,
              writable: ->(*) { can_create_or_manage_users? }

    attribute :status,
              writable: ->(*) { can_create_or_manage_users? }

    attribute :force_password_change,
              writable: ->(*) { user.admin? }

    def self.model
      User
    end

    validate :validate_password_writable
    validate :validate_identity_url_writable
    validate :existing_auth_source

    delegate :available_custom_fields, to: :model

    def reduce_writable_attributes(attributes)
      super.tap do |writable|
        # `password` and `identity_url` are not regular attributes so they bypass
        # attribute writable checks. therewore they must be added to the list
        # of writable attributes under certain conditions.
        writable << "password" if password_writable?
        writable << "identity_url" if identity_url_writable?
      end
    end

    private

    def password_writable?
      return true if user.admin? && !editing_self?

      editing_self? && current_password_valid?
    end

    def current_password_valid?
      return true if model.password.blank?

      provided_current_password = model.current_password_input
      provided_current_password.present? && model.check_password?(provided_current_password)
    end

    def identity_url_writable?
      user.admin?
    end

    ##
    # User#password is not an ActiveModel property,
    # but just an accessor, so we need to identify it being written there.
    # It is only present when freshly written
    def validate_password_writable
      return if model.password.blank?
      return if password_writable?

      if editing_self?
        errors.add :current_password, :invalid
      else
        errors.add :password, :error_readonly
      end
    end

    def validate_identity_url_writable
      return if identity_url_writable?

      errors.add(:identity_url, :error_readonly) if model.user_auth_provider_links.any?(&:changed?)
    end

    def existing_auth_source
      if ldap_auth_source_id && LdapAuthSource.find_by_unique(ldap_auth_source_id).nil?
        errors.add :auth_source, :error_not_found
      end
    end

    def can_create_or_manage_users?
      user.allowed_globally?(:manage_user) || user.allowed_globally?(:create_user)
    end

    def editing_self?
      model.id == user.id
    end

    def can_change_self?
      # Editing of own attributes is disallowed when external auth source defines attributes
      return false if authenticates_externally?

      editing_self?
    end

    def authenticates_externally?
      model.uses_external_authentication? || model.ldap_auth_source_id
    end
  end
end

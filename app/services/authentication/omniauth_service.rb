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

module Authentication
  class OmniauthService
    include Contracted

    attr_accessor :auth_hash,
                  :strategy,
                  :controller,
                  :contract,
                  :user_attributes,
                  :user

    delegate :session, to: :controller

    def initialize(strategy:, auth_hash:, controller:)
      self.strategy = strategy
      self.auth_hash = auth_hash
      self.controller = controller
      self.contract = ::Authentication::OmniauthAuthHashContract.new(auth_hash)
    end

    def call(additional_user_params = nil)
      inspect_response(Logger::DEBUG)

      unless contract.validate
        result = ServiceResult.failure(errors: contract.errors)
        Rails.logger.error do
          # Try to provide some context of the auth_hash in case of errors
          auth_uid = begin
            hash = auth_hash || {}
            hash.dig(:info, :uid) || hash[:uid] || "unknown"
          end
          "[OmniAuth strategy #{strategy.name}] Failed to process omniauth response for #{auth_uid}: #{result.message}"
        end
        inspect_response(Logger::ERROR)

        return result
      end

      # Create or update the user from omniauth
      # and assign non-nil parameters from the registration form - if any
      assignable_params = (additional_user_params || {}).compact
      update_user_from_omniauth!(assignable_params)

      # If we have a new or invited user, we still need to register them
      call = activate_user!

      # Update the admin flag when present successful
      call = update_admin_flag(call) if call.success?

      # The user should be logged in now
      tap_service_result call
    end

    private

    ##
    # Inspect the response object, trying to find out what got returned
    def inspect_response(log_level)
      case strategy
      when ::OmniAuth::Strategies::SAML
        ::OpenProject::AuthSaml::Inspector.inspect_response(auth_hash) do |message|
          Rails.logger.add log_level, message
        end
      else
        Rails.logger.add(log_level) do
          "[OmniAuth strategy #{strategy.name}] Returning from omniauth with hash " \
            "#{auth_hash&.to_hash.inspect} Valid? #{auth_hash&.valid?}"
        end
      end
    rescue StandardError => e
      OpenProject.logger.error "[OmniAuth strategy #{strategy&.name}] Failed to inspect OmniAuth response: #{e.message}"
    end

    ##
    # After login flow
    def tap_service_result(call)
      if call.success? && user.active?
        OpenProject::Hook.call_hook :omniauth_user_authorized, { auth_hash:, controller: }
        # Call deprecated login hook
        OpenProject::OmniAuth::Authorization.after_login! user, auth_hash, self
      end

      call
    end

    ##
    # After validating the omniauth hash
    # and the authorization is successful,
    #
    # login the user by locating or creating it
    def update_user_from_omniauth!(additional_user_params)
      # Find or create the user from the auth hash
      self.user_attributes = build_omniauth_hash_to_user_attributes.merge(additional_user_params)
      self.user = lookup_or_initialize_user

      # Assign or update the user with the omniauth attributes
      update_attributes
    end

    ##
    # Try to find or create the user
    # in the following order:
    #
    # 1. Look for an active invitation token
    # 2. Look for an existing user for the current identity_url
    # 3. Look for an existing user that we can remap (IF remapping is allowed)
    # 4. Try to register a new user and activate according to settings
    def lookup_or_initialize_user
      find_invited_user ||
        find_existing_user ||
        remap_existing_user ||
        User.new
    end

    ##
    # Return an invited user, if there is a token
    def find_invited_user
      return unless session.include?(:invitation_token)

      token = Token::Invitation.find_by value: session[:invitation_token]
      return unless token

      token.user.tap do |user|
        if user_attributes[:identity_url].present?
          slug, external_id = user_attributes[:identity_url].split(":", 2)
          link = user.user_auth_provider_links.find_or_initialize_by(auth_provider: AuthProvider.find_by!(slug:))
          link.external_id = external_id
          link.save!
        end
        token.destroy
        session.delete :invitation_token
      end
    end

    ##
    # Find an existing user by the identity url
    def find_existing_user
      if developer_provider?
        User.find_by(mail: auth_hash[:uid])
      else
        UserAuthProviderLink
          .left_joins(:principal)
          .where(principal: { type: "User" })
          .with_identity_url(user_attributes[:identity_url])
          .first
          &.principal
      end
    end

    ##
    # Allow to map existing users with an Omniauth source if the login already exists
    def remap_existing_user
      return unless Setting.oauth_allow_remapping_of_existing_users?

      User.not_builtin.find_by_login(user_attributes[:login])
    end

    ##
    # Update or assign the user attributes
    def update_attributes
      if user.new_record? || user.invited?
        user.register unless user.invited?

        ::Users::SetAttributesService
          .new(user: User.system, model: user, contract_class: ::Users::UpdateContract)
          .call(user_attributes)
      else
        # Update the user, but do not change the admin flag
        # as this call is not validated.
        # we do this separately in +update_admin_flag+
        ::Users::UpdateService
          .new(user: User.system, model: user)
          .call(user_attributes.except(:admin))
      end
    end

    def update_admin_flag(call)
      return call unless user_attributes.key?(:admin)

      new_admin = ActiveRecord::Type::Boolean.new.cast(user_attributes[:admin])
      return call if user.admin == new_admin

      ::Users::UpdateService
        .new(user: User.system, model: user)
        .call(admin: new_admin)
        .on_failure { |res| update_admin_flag_failure(res) }
        .on_success { update_admin_flag_success(new_admin) }
    end

    def update_admin_flag_success(new_admin)
      if new_admin
        OpenProject.logger.info { "[OmniAuth strategy #{strategy.name}] Granted user##{update.result.id} admin permissions" }
      else
        OpenProject.logger.info { "[OmniAuth strategy #{strategy.name}] Revoked user##{update.result.id} admin permissions" }
      end
    end

    def update_admin_flag_failure(call)
      OpenProject.logger.error do
        "[OmniAuth strategy #{strategy.name}] Failed to update admin user permissions: #{call.message}"
      end
    end

    def activate_user!
      if activatable?
        ::Users::RegisterUserService
          .new(user)
          .call
      else
        ServiceResult.success(result: user)
      end
    end

    ##
    # Determines if the given user is activatable on the fly, that is:
    #
    # 1. The user has just been initialized by us
    # 2. The user has been invited
    # 3. The user had been registered manually (e.g., through a previous self-registration setting)
    def activatable?
      user.new_record? || user.invited? || user.registered?
    end

    ##
    # Maps the omniauth attribute hash
    # to our internal user attributes
    def build_omniauth_hash_to_user_attributes
      info = auth_hash[:info]

      attribute_map = {
        login: info[:login] || info[:email],
        mail: info[:email],
        firstname: info[:first_name] || info[:name],
        lastname: info[:last_name],
        identity_url: identity_url_from_omniauth
      }

      # Map the admin attribute if provided in an attribute mapping
      attribute_map[:admin] = ActiveRecord::Type::Boolean.new.cast(info[:admin]) if info.key?(:admin)

      # Allow strategies to override mapping
      if strategy.respond_to?(:omniauth_hash_to_user_attributes)
        attribute_map.merge!(strategy.omniauth_hash_to_user_attributes(auth_hash))
      end

      # Remove any nil values to avoid
      # overriding existing attributes
      attribute_map.reject! { |_, value| value.nil? || value == "" }

      Rails.logger.debug { "Mapped auth_hash user attributes #{attribute_map.inspect}" }
      attribute_map
    end

    ##
    # Allow strategies to map a value for uid instead
    # of always taking the global UID.
    # For SAML, the global UID may change with every session
    # (in case of transient nameIds)
    def identity_url_from_omniauth
      return if developer_provider?

      identifier = auth_hash[:info][:uid] || auth_hash[:uid]
      "#{auth_hash[:provider]}:#{identifier}"
    end

    ##
    # Indicates whether OmniAuth::Strategies::Delevoper strategy is used.
    # https://github.com/omniauth/omniauth/blob/0bcfd5b25bf946422cd4d9c40c4f514121ac04d6/lib/omniauth/strategies/developer.rb
    # if true:
    #   identity_url should not be set and
    #   user should be found by mail, because mail plays uid role in developer strategy
    def developer_provider?
      Rails.env.local? && auth_hash[:provider] == "developer"
    end
  end
end

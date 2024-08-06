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
  class RegisterUserService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      %i[
        ensure_user_limit_not_reached!
        register_invited_user
        register_ldap_user
        ensure_provider_not_limited!
        register_omniauth_user
        ensure_registration_allowed!
        register_by_email_activation
        register_automatically
        register_manually
        fail_activation
      ].each do |m|
        result = send(m)
        return result if result.is_a?(ServiceResult)
      end
    rescue StandardError => e
      Rails.logger.error { "User #{user.login} failed to activate #{e}." }
      ServiceResult.failure(result: user, message: I18n.t(:notice_activation_failed))
    end

    private

    ##
    # Check whether the associated single sign-on providers
    # allows for automatic activation of new users
    def ensure_provider_not_limited!
      if limited_provider?(user) && Setting::SelfRegistration.disabled?
        name = provider_name(user)
        ServiceResult.failure(result: user, message: I18n.t("account.error_self_registration_limited_provider", name:))
      end
    end

    ##
    # Check whether the system allows registration
    # for non-invited users
    def ensure_registration_allowed!
      if Setting::SelfRegistration.disabled?
        ServiceResult.failure(result: user, message: I18n.t("account.error_self_registration_disabled"))
      end
    end

    ##
    # Ensure the user limit is not reached
    def ensure_user_limit_not_reached!
      if OpenProject::Enterprise.user_limit_reached?
        OpenProject::Enterprise.send_activation_limit_notification_about user
        ServiceResult.failure(result: user, message: I18n.t(:error_enterprise_activation_user_limit))
      end
    end

    ##
    # Try to register an invited user
    # bypassing regular restrictions
    def register_invited_user
      return unless user.invited?

      user.activate

      with_saved_user_result(success_message: I18n.t(:notice_account_registered_and_logged_in)) do
        Rails.logger.info { "User #{user.login} was successfully activated after invitation." }
      end
    end

    ##
    # Try to register a user with an auth source connection
    # bypassing regular account registration restrictions
    def register_ldap_user
      return if user.ldap_auth_source_id.blank?

      user.activate

      with_saved_user_result(success_message: I18n.t(:notice_account_registered_and_logged_in)) do
        Rails.logger.info { "User #{user.login} was successfully activated with LDAP association after invitation." }
      end
    end

    ##
    # Try to register a user with an existsing omniauth connection
    # bypassing regular account registration restrictions
    def register_omniauth_user
      return if skip_omniauth_user?
      return if limited_provider?(user)

      user.activate

      with_saved_user_result(success_message: I18n.t(:notice_account_registered_and_logged_in)) do
        Rails.logger.info { "User #{user.login} was successfully activated after arriving from omniauth." }
      end
    end

    def skip_omniauth_user?
      user.identity_url.blank?
    end

    def limited_provider?(user)
      provider = provider_name(user)
      return false if provider.blank?

      OpenProject::Plugins::AuthPlugin.limit_self_registration?(provider:)
    end

    def provider_name(user)
      user.authentication_provider&.downcase
    end

    def register_by_email_activation
      return unless Setting::SelfRegistration.by_email?

      user.register

      with_saved_user_result(success_message: I18n.t(:notice_account_register_done)) do
        token = Token::Invitation.create!(user:)
        UserMailer.user_signed_up(token).deliver_later
        Rails.logger.info { "Scheduled email activation mail for #{user.login}" }
      end
    end

    # Automatically register a user
    #
    # Pass a block for behavior when a user fails to save
    def register_automatically
      return unless Setting::SelfRegistration.automatic?

      user.activate

      with_saved_user_result do
        Rails.logger.info { "User #{user.login} was successfully activated." }
      end
    end

    def register_manually
      user.register

      with_saved_user_result(success_message: I18n.t(:notice_account_pending)) do
        # Sends an email to the administrators
        admins = User.admin.active
        admins.each do |admin|
          UserMailer.account_activation_requested(admin, user).deliver_later
        end

        Rails.logger.info { "User #{user.login} was successfully created and is pending admin activation." }
      end
    end

    def fail_activation
      Rails.logger.error { "User #{user.login} could not be activated, all options were exhausted." }
      ServiceResult.failure(message: I18n.t(:notice_activation_failed))
    end

    ##
    # Try to save result, return it in case of errors
    # and add a user error to make sure we can render the account registration form
    def with_saved_user_result(success_message: I18n.t(:notice_account_activated))
      if user.save
        yield if block_given?
        return ServiceResult.success(result: user, message: success_message)
      end

      ServiceResult.failure.tap do |call|
        # Avoid using the errors from the user
        call.result = user
        call.errors.add(:base, I18n.t(:notice_activation_failed), error: :failed_to_activate)
      end
    end
  end
end

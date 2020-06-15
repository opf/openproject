#-- encoding: UTF-8
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

module Users
  class RegisterUserService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      %i[
        register_invited_user
        ensure_registration_allowed!
        ensure_user_limit_not_reached!
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
      ServiceResult.new(success: false, result: user, message: I18n.t(:notice_activation_failed))
    end

    private

    ##
    # Check whether the system allows registration
    # for non-invited users
    def ensure_registration_allowed!
      if Setting::SelfRegistration.disabled?
        ServiceResult.new(success: false, result: user, message: I18n.t('account.error_self_registration_disabled'))
      end
    end

    ##
    # Ensure the user limit is not reached
    def ensure_user_limit_not_reached!
      if OpenProject::Enterprise.user_limit_reached?
        OpenProject::Enterprise.send_activation_limit_notification_about user
        ServiceResult.new(success: false, result: user, message: I18n.t(:error_enterprise_activation_user_limit))
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

    def register_by_email_activation
      return unless Setting::SelfRegistration.by_email?

      user.register

      with_saved_user_result(success_message: I18n.t(:notice_account_register_done)) do
        token = Token::Invitation.create!(user: user)
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
      ServiceResult.new(success: false, message: I18n.t(:notice_activation_failed))
    end

    ##
    # Try to save result, return it in case of errors
    # and add a user error to make sure we can render the account registration form
    def with_saved_user_result(success_message: I18n.t(:notice_account_activated))
      if user.save
        yield if block_given?
        return ServiceResult.new(success: true, result: user, message: success_message)
      end

      ServiceResult.new(success: false, result: user).tap do |result|
        result.errors.add(:base, :failed_to_activate)
      end
    end
  end
end

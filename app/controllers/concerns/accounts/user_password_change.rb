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

##
# Intended to be used by the MyController and AccountController for password change flows
module Accounts::UserPasswordChange
  ##
  # Process a password change form, used when the user is forced
  # to change the password.
  # When making changes here, also check MyController.change_password
  def change_password_flow(user:, params:, update_legacy: true, show_user_name: false)
    return render_404 if OpenProject::Configuration.disable_password_login?

    # A JavaScript hides the force_password_change field for external
    # auth sources in the admin UI, so this shouldn't normally happen.
    return if redirect_if_password_change_not_allowed(user)

    # Ensure the current password is validated
    unless user.check_password?(params[:password], update_legacy:)
      flash_and_log_invalid_credentials(is_logged_in: !show_user_name)
      return render_password_change(user, nil, show_user_name:)
    end

    # Call the service to set the new password
    call = ::Users::ChangePasswordService.new(current_user: @user, session:).call(params)

    # Yield the success to the caller
    if call.success?
      response = yield call

      call.apply_flash_message!(flash)
      return response
    end

    # Render the username to hint to a user in case of a forced password change
    render_password_change user, call.message, show_user_name:
  end

  ##
  # Log an attempt to log in to a locked account or with invalid credentials
  # and show a flash message.
  def flash_and_log_invalid_credentials(flash_now: true, is_logged_in: false)
    if is_logged_in
      flash[:error] = I18n.t(:notice_account_wrong_password)
      return
    end

    flash_error_message(log_reason: 'invalid credentials', flash_now:) do
      if Setting.brute_force_block_after_failed_logins.to_i > 0
        :notice_account_invalid_credentials_or_blocked
      else
        :notice_account_invalid_credentials
      end
    end
  end

  def render_password_change(user, message, show_user_name: false)
    flash[:error] = message unless message.nil?
    @user = user
    @username = user.login
    render 'my/password', locals: { show_user_name: }
  end

  ##
  # Redirect if the user cannot change its password
  def redirect_if_password_change_not_allowed(user)
    if user and not user.change_password_allowed?
      logger.warn "Password change for user '#{user}' forced, but user is not allowed " +
                  'to change password'
      flash[:error] = I18n.t(:notice_can_t_change_password)
      redirect_to action: 'login'
      return true
    end
    false
  end

  def flash_error_message(log_reason: '', flash_now: true)
    flash_hash = flash_now ? flash.now : flash

    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} " \
                "at #{Time.now.utc}: #{log_reason}"

    flash_message = yield

    flash_hash[:error] = I18n.t(flash_message)
  end
end

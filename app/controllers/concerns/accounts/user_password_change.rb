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

##
# Intended to be used by the MyController and AccountController for password change flows
module Accounts::UserPasswordChange
  ##
  # Process a password change form, used when the user is forced
  # to change the password.
  # When making changes here, also check MyController.change_password
  def change_password_flow(user:, params:, update_legacy: true, show_user_name: false)
    return render_404 if Users::PasswordLogin.none?

    # A JavaScript hides the force_password_change field for external
    # auth sources in the admin UI, so this shouldn't normally happen.
    return if redirect_if_password_change_not_allowed(user)

    rejection = reject_password_change_attempt(user, params, update_legacy:, show_user_name:)
    return rejection if rejection

    call = ::Users::ChangePasswordService.new(current_user: @user, session:).call(params)

    if call.success?
      User.reset_failed_login_count_for(user)

      response = yield call

      call.apply_flash_message!(flash)
      return response
    end

    render_password_change user, call.message, show_user_name:
  end

  def reject_password_change_attempt(user, params, update_legacy:, show_user_name:)
    if user.failed_too_many_recent_login_attempts?
      return invalid_password_change_response(user, show_user_name:)
    end

    unless user.check_password?(params[:password], update_legacy:)
      user.log_failed_login
      return invalid_password_change_response(user, show_user_name:)
    end

    nil
  end

  def invalid_password_change_response(user, show_user_name:)
    flash_and_log_invalid_credentials(is_logged_in: !show_user_name)
    render_password_change(user, nil, show_user_name:)
  end

  def render_password_change(user, message, show_user_name: false)
    flash[:error] = message unless message.nil?
    @user = user
    @username = user.login
    render "my/password", locals: { show_user_name: }, status: :unprocessable_entity
  end

  ##
  # Redirect if the user cannot change its password
  def redirect_if_password_change_not_allowed(user)
    if user and not user.change_password_allowed?
      logger.warn "Password change for user '#{user}' forced, but user is not allowed " +
                  "to change password"
      flash[:error] = I18n.t(:notice_can_t_change_password)
      redirect_to action: "login"
      return true
    end
    false
  end
end

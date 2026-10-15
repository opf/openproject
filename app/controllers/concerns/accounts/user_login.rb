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

module Accounts::UserLogin
  include ::Accounts::AuthenticationStages
  include ::Accounts::RedirectAfterLogin

  def login_user!(user)
    # Set the logged user, resetting their session
    self.logged_user = user

    call_hook(:controller_account_success_authentication_after, user:)

    redirect_after_login(user)
  end

  ##
  # Log an attempt to log in to a locked account or with invalid credentials
  # and show a flash message.
  def flash_and_log_invalid_credentials(flash_now: true, is_logged_in: false, sso_hint: false)
    if is_logged_in
      flash[:error] = I18n.t(:notice_account_wrong_password)
      return
    end

    flash_error_message(log_reason: "invalid credentials", flash_now:) do
      [invalid_credentials_message, (sso_login_hint if sso_hint)].compact.join(" ")
    end
  end

  def flash_error_message(log_reason: "", flash_now: true)
    flash_hash = flash_now ? flash.now : flash

    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} " \
                "at #{Time.now.utc}: #{log_reason}"

    flash_hash[:error] = yield
  end

  private

  def invalid_credentials_message
    if Setting.brute_force_block_after_failed_logins.to_i > 0
      I18n.t(:notice_account_invalid_credentials_or_blocked)
    else
      I18n.t(:notice_account_invalid_credentials)
    end
  end

  def sso_login_hint
    return unless Users::PasswordLogin.restricted?

    I18n.t(:notice_account_invalid_credentials_sso_hint)
  end
end

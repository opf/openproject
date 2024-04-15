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
# Intended to be used by the UsersController to enforce the user limit.
module Accounts::UserLimits
  def enforce_user_limit(
    redirect_to: users_path,
    hard: OpenProject::Enterprise.fail_fast?,
    flash_now: false
  )
    if user_limit_reached?
      if hard
        show_user_limit_error!

        redirect_back fallback_location: redirect_to
      else
        show_user_limit_warning! flash_now:
      end

      true
    elsif imminent_user_limit?
      show_imminent_user_limit_warning!(flash_now:)

      true
    else
      false
    end
  end

  def enforce_activation_user_limit(user: nil, redirect_to: signin_path)
    if user_limit_reached?
      flash[:error] = I18n.t(:error_enterprise_activation_user_limit)
      send_activation_limit_notification_about user if user

      redirect_back fallback_location: redirect_to

      true
    else
      false
    end
  end

  ##
  # Ensures that the given user object has an email set.
  # If it hasn't it takes the value from the params.
  def user_with_email(user)
    user.mail = permitted_params.user["mail"] if user.mail.blank?
    user
  end

  def send_activation_limit_notification_about(user)
    OpenProject::Enterprise.send_activation_limit_notification_about user
  end

  def show_user_limit_warning!(flash_now: false)
    f = flash_now ? flash.now : flash

    f[:warning] = user_limit_warning
  end

  def show_user_limit_error!
    flash[:error] = user_limit_warning
  end

  def user_limit_warning
    warning = if current_user.admin?
                I18n.t(
                  :warning_user_limit_reached_admin,
                  upgrade_url: OpenProject::Enterprise.upgrade_url
                )
              else
                I18n.t(
                  :warning_user_limit_reached
                )
              end

    warning.html_safe
  end

  def show_imminent_user_limit_warning!(flash_now: false)
    f = flash_now ? flash.now : flash

    f[:warning] = imminent_user_limit_warning
  end

  ##
  # A warning for when the user limit has technically not been reached yet
  # but if all invited users were to activate their accounts it would be reached.
  def imminent_user_limit_warning
    warning = I18n.t(
      :warning_imminent_user_limit,
      upgrade_url: OpenProject::Enterprise.upgrade_url
    )

    warning.html_safe
  end

  def user_limit_reached?
    OpenProject::Enterprise.user_limit_reached?
  end

  def imminent_user_limit?
    OpenProject::Enterprise.imminent_user_limit?
  end
end

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
# Enforces the inactivity session TTL and tracks session activity.
#
# Intended to be used by the ApplicationController via a +before_action :check_session_lifetime+.
module Accounts::SessionLifetime
  extend ActiveSupport::Concern

  include ::OpenProject::Authentication::SessionExpiration

  # Minimum age of session[:updated_at] before we refresh it.
  # Previously, we would bump it on every request, which causes an unnecessary session write.
  # The minimum TTL value is 5.minutes, so we set this to half of that.
  SESSION_ACTIVITY_REFRESH_INTERVAL = 2.minutes

  protected

  def check_session_lifetime
    if session_expired?
      terminate_user_session
    else
      refresh_session_activity
    end
  end

  private

  def terminate_user_session
    self.logged_user = nil

    flash[:warning] = I18n.t("notice_forced_logout", ttl_time: Setting.session_ttl)
    redirect_to(controller: "/account", action: "login", back_url: login_back_url)
  end

  def session_expired?
    !api_request? && current_user.logged? && session_ttl_expired?
  end

  # Only write to the esssion if we really need to to prevent a session write
  # that has no effect other than the updated_at.
  def refresh_session_activity
    last_seen = session[:updated_at]
    return if last_seen.present? && last_seen > SESSION_ACTIVITY_REFRESH_INTERVAL.ago

    session[:updated_at] = Time.zone.now
  end
end

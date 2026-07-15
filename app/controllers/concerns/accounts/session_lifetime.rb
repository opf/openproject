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

  # We refresh session[:updated_at] (causing a database write in our session store) at most
  # once per the interval below, rather than on every request.
  #
  # Doing that MAY cause the session to expire within one interval earlier than its TTL,
  # but it will never be expired later than that, ensuring that the setting is considered a maximum.
  #
  # The interval is a fraction of the configured TTL, with min and max values at 1 and 5 minutes respectively.
  # This alllows us to save more writes on longer TTLs, while keeping the "expire ahead" minimal for smaller values.
  SESSION_ACTIVITY_REFRESH_RATIO = 0.2
  SESSION_ACTIVITY_REFRESH_MIN = 1.minute
  SESSION_ACTIVITY_REFRESH_MAX = 5.minutes

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

  # Only write to the session if we really need to, to prevent a session write
  # that has no effect other than bumping updated_at.
  def refresh_session_activity
    last_seen = session[:updated_at]
    return if last_seen.present? && last_seen > session_activity_refresh_interval.ago

    session[:updated_at] = Time.zone.now
  end

  # See the SESSION_ACTIVITY_REFRESH_* constants. Without a TTL only the 30-day
  # cleanup cares about updated_at, so the maximum interval is enough.
  def session_activity_refresh_interval
    return SESSION_ACTIVITY_REFRESH_MAX unless session_ttl_enabled?

    scaled = (session_ttl_minutes.to_i * SESSION_ACTIVITY_REFRESH_RATIO).round
    # Ensure our value it stays between the min and max interval
    scaled.clamp(SESSION_ACTIVITY_REFRESH_MIN.to_i, SESSION_ACTIVITY_REFRESH_MAX.to_i).seconds
  end
end

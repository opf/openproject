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

module Pwa
  class PushNotificationsController < ApplicationController
    prepend_before_action :prevent_response_caching
    before_action :require_login
    guard_feature_flag :progressive_web_app
    before_action :require_web_push
    no_authorization_required! :show

    def show
      render json: PushSubscriptions::NotificationSummary.new(current_user)
    end

    private

    # Notifications arriving in the background neither keep the user signed in nor sign
    # them out of other devices when this session times out.
    def check_session_lifetime
      return unless current_user.logged? && session_ttl_expired?

      Users::LogoutService.new(controller: self).call!(current_user, drop_other_sessions: false)
      head :unauthorized
    end

    # Background wake-ups may only confirm the existing browser session, never start,
    # switch or extend one; an SSO header can only reject a session it doesn't match.
    def find_current_user
      user = current_session_user
      user if user && sso_header_accepts?(user)
    end

    def sso_header_accepts?(user)
      return true unless auth_source_sso_enabled?
      return header_optional? if op_auth_header_value.blank?

      login = read_sso_login
      login.present? && user.login.casecmp?(login)
    end

    def require_web_push
      render_404 unless Setting.web_push_enabled?
    end
  end
end

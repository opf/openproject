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

module My
  class SessionsController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :index,
                               :destroy

    before_action :load_session, only: %i(destroy)
    before_action :prevent_current_session_deletion, only: %i(destroy)

    layout "my"
    menu_item :sessions

    def index
      @autologin_tokens = ::Token::AutoLogin
        .for_user(current_user)
        .order(expires_on: :asc)

      @unmapped_sessions = ::Sessions::UserSession
        .for_user(current_user)
        .not_autologged
        .order(updated_at: :desc)

      token = cookies[OpenProject::Configuration["autologin_cookie_name"]]
      if token
        @current_token = @autologin_tokens.find_by_plaintext_value(token)
      end
    end

    def destroy
      @session.delete

      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to action: :index, status: :see_other
    end

    private

    def load_session
      @session = ::Sessions::UserSession.for_user(current_user).find(params[:id])
    end

    def prevent_current_session_deletion
      if @session.current?(session)
        render_400 message: I18n.t("users.sessions.may_not_delete_current")
      end
    end
  end
end

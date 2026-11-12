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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module My
  class AutoLoginTokensController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :destroy

    before_action :find_token, only: %i(destroy)

    layout "my"
    menu_item :sessions

    def destroy
      @token.destroy

      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to my_sessions_path, status: :see_other
    end

    private

    def find_token
      @token = Token::AutoLogin
        .for_user(current_user)
        .find(params[:id])
    end
  end
end

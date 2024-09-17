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

module OAuth
  class GrantsController < ::ApplicationController
    before_action :require_login
    authorization_checked! :index, :revoke_application

    layout "my"
    menu_item :access_token

    def index
      @applications = ::Doorkeeper::Application.authorized_for(current_user)
    end

    def revoke_application
      application = find_application
      if application.nil?
        render_404
        return
      end

      ::Doorkeeper::Application.revoke_tokens_and_grants_for(
        application.id,
        current_user
      )

      flash[:notice] = I18n.t("oauth.grants.successful_application_revocation", application_name: application.name)
      redirect_to controller: "/my", action: :access_token
    end

    private

    def find_application
      ::Doorkeeper::Application
        .authorized_for(current_user)
        .where(id: params[:application_id])
        .select(:name, :id)
        .take
    end
  end
end

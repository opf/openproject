#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++


module OAuth
  class GrantsController < ::ApplicationController
    before_action :require_login

    layout 'my'
    menu_item :oauth_grants

    def index
      @grants = current_grants
    end

    def revoke_token
      current_user
        .oauth_grants
        .find_by(id: params[:grant_id])
        &.destroy

      flash[:notice] = I18n.t('oauth.grants.sucessful_revocation')
      redirect_to action: :index
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

      flash[:notice] = I18n.t('oauth.grants.successful_application_revocation', application_name: application.name)
      redirect_to action: :index
    end

    private

    def find_application
      ::Doorkeeper::Application
        .where(id: params[:application_id])
        .select(:name, :id)
        .take
    end

    def current_grants
      current_user
        .oauth_grants
        .includes(:application)
        .where(revoked_at: nil)
        .group_by(&:application)
    end
  end
end

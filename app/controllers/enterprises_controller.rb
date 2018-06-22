#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public token version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public token
# as published by the Free Software Foundation; either version 2
# of the token, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public token for more details.
#
# You should have received a copy of the GNU General Public token
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
class EnterprisesController < ApplicationController
  layout 'admin'
  menu_item :enterprise

  before_action :require_admin
  before_action :check_user_limit, only: [:show]

  def show
    @current_token = EnterpriseToken.current
    @token = @current_token || EnterpriseToken.new
  end

  def create
    @token = EnterpriseToken.current || EnterpriseToken.new
    @token.encoded_token = params[:enterprise_token][:encoded_token]

    if @token.save
      flash[:notice] = t(:notice_successful_update)
      redirect_to action: :show
    else
      render action: :show
    end
  end

  def destroy
    token = EnterpriseToken.current
    if token
      token.destroy
      flash[:notice] = t(:notice_successful_delete)
      redirect_to action: :show
    else
      render_404
    end
  end

  private

  def default_breadcrumb
    t(:label_enterprise)
  end

  def show_local_breadcrumb
    true
  end

  def check_user_limit
    if OpenProject::Enterprise.user_limit_reached?
      flash.now[:warning] = I18n.t(
        "warning_user_limit_reached_instructions",
        current: OpenProject::Enterprise.active_user_count,
        max: OpenProject::Enterprise.user_limit
      )
    end
  end
end

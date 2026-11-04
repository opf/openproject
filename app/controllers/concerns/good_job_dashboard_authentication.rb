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

module GoodJobDashboardAuthentication
  extend ActiveSupport::Concern
  include OpenProject::Authentication::SessionExpiration

  included do
    prepend_before_action :require_openproject_admin
    after_action :prevent_dashboard_caching
  end

  private

  def require_openproject_admin
    reset_session if session_ttl_expired?

    user = User.active.find_by(id: session[:user_id]) if session[:user_id]
    return require_openproject_login unless user
    return head :forbidden unless user.admin?

    session[:updated_at] = Time.current
  end

  def require_openproject_login
    if request.format.html?
      redirect_to main_app.signin_path(back_url: main_app.admin_good_job_dashboard_path)
    else
      head :unauthorized
    end
  end

  def prevent_dashboard_caching
    no_store
  end
end

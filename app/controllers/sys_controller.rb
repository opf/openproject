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

require "open_project/repository_authentication"

class SysController < ActionController::Base
  include Security::DefaultUrlOptions

  before_action :check_enabled
  before_action :require_basic_auth, only: [:repo_auth]

  # disable CSRF protection since the Sys API does not use sessions
  skip_before_action :verify_authenticity_token

  def repo_auth
    project = Project.find_by(identifier: params[:repository])
    if project && authorized?(project, @authenticated_user)
      render plain: "Access granted"
    else
      render plain: "Not allowed", status: :forbidden # default to deny
    end
  end

  def fetch_changesets
    projects = []
    if params[:id]
      projects << Project.active.has_module(:repository).find_by!(identifier: params[:id])
    else
      projects = Project.active.has_module(:repository)
                        .includes(:repository).references(:repositories)
    end
    projects.each do |project|
      if project.repository
        project.repository.fetch_changesets
      end
    end
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def authorized?(project, user)
    repository = project.repository

    if repository && repository.class.authorization_policy
      repository.class.authorization_policy.new(project, user).authorized?(params)
    else
      false
    end
  end

  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render plain: "Access denied. Repository management WS is disabled or key is invalid.",
             status: :forbidden
      false
    end
  end

  def require_basic_auth
    authenticate_with_http_basic do |username, password|
      @authenticated_user = user_login(username, password)
      return true if @authenticated_user
    end

    response.headers["WWW-Authenticate"] = 'Basic realm="Repository Authentication"'
    render plain: "Authorization required", status: :unauthorized
    false
  end

  def user_login(username, password)
    User.try_to_login(username, password)
  end
end

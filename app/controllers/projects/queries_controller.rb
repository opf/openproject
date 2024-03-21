# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class Projects::QueriesController < ApplicationController
  include Projects::QueryLoading

  # No need for a more specific authorization check. That is carried out in the contracts.
  before_action :require_login
  before_action :find_query, only: :destroy
  before_action :load_query_or_deny_access, only: %i[new]

  current_menu_item [:new, :create] do
    :projects
  end

  def new
    render template: '/projects/index',
           layout: 'global',
           locals: { query: @query, state: :edit }
  end

  def create
    call = Queries::Projects::ProjectQueries::CreateService
             .new(user: current_user)
             .call(permitted_query_params)

    if call.success?
      redirect_to projects_path(query_id: call.result.id)
    else
      render template: '/projects/index',
             layout: 'global',
             locals: { query: call.result, state: :edit }
    end
  end

  def destroy
    Queries::Projects::ProjectQueries::DeleteService.new(user: current_user, model: @query)
                                                    .call

    redirect_to projects_path
  end

  private

  def find_query
    @query = Queries::Projects::ProjectQuery.find(params[:id])
  end
end

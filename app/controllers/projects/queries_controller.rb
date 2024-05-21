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
  before_action :find_query, only: %i[rename update destroy publish unpublish]
  before_action :build_query_or_deny_access, only: %i[new create]

  current_menu_item [:new, :rename, :create, :update] do
    :projects
  end

  def new
    render template: "/projects/index",
           layout: "global",
           locals: { query: @query, state: :edit }
  end

  def rename
    render template: "/projects/index",
           layout: "global",
           locals: { query: @query, state: :rename }
  end

  def create
    call = Queries::Projects::ProjectQueries::CreateService
             .new(from: @query, user: current_user)
             .call(permitted_query_params)

    render_result(call, success_i18n_key: "lists.create.success", error_i18n_key: "lists.create.failure")
  end

  def update
    call = Queries::Projects::ProjectQueries::UpdateService
             .new(user: current_user, model: @query)
             .call(permitted_query_params)

    render_result(call, success_i18n_key: "lists.update.success", error_i18n_key: "lists.update.failure")
  end

  def publish
    call = Queries::Projects::ProjectQueries::PublishService
             .new(user: current_user, model: @query)
             .call(public: true)

    render_result(call, success_i18n_key: "lists.publish.success", error_i18n_key: "lists.publish.failure")
  end

  def unpublish
    call = Queries::Projects::ProjectQueries::PublishService
             .new(user: current_user, model: @query)
             .call(public: false)

    render_result(call, success_i18n_key: "lists.unpublish.success", error_i18n_key: "lists.unpublish.failure")
  end

  def destroy
    Queries::Projects::ProjectQueries::DeleteService.new(user: current_user, model: @query)
                                                    .call

    redirect_to projects_path
  end

  private

  def render_result(service_call, success_i18n_key:, error_i18n_key:)
    if service_call.success?
      flash[:notice] = I18n.t(success_i18n_key)

      redirect_to projects_path(query_id: service_call.result.id)
    else
      flash[:error] = I18n.t(error_i18n_key, errors: service_call.errors.full_messages.join("\n"))

      render template: "/projects/index",
             layout: "global",
             locals: { query: service_call.result, state: :edit }
    end
  end

  def find_query
    @query = Queries::Projects::ProjectQuery.visible(user: current_user).find(params[:id])
  end
end
